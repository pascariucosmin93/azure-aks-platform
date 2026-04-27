locals {
  backend_pool_name   = "aks-backend"
  http_setting_name   = "aks-http"
  http_listener_name  = "http-listener"
  https_listener_name = "https-listener"
  redirect_name       = "http-to-https"
  frontend_ip_name    = "public"
  port_http_name      = "port-80"
  port_https_name     = "port-443"
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-agw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "${var.prefix}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
    }
  }

  tags = var.tags
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.prefix}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.main.id
  zones               = ["1", "2", "3"]

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_name
    public_ip_address_id = azurerm_public_ip.main.id
  }

  frontend_port {
    name = local.port_http_name
    port = 80
  }

  frontend_port {
    name = local.port_https_name
    port = 443
  }

  backend_address_pool {
    name = local.backend_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "aks-health-probe"
  }

  probe {
    name                = "aks-health-probe"
    protocol            = "Http"
    path                = "/healthz"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_name
    frontend_port_name             = local.port_http_name
    protocol                       = "Http"
  }

  dynamic "http_listener" {
    for_each = var.ssl_certificate_name != null ? [1] : []
    content {
      name                           = local.https_listener_name
      frontend_ip_configuration_name = local.frontend_ip_name
      frontend_port_name             = local.port_https_name
      protocol                       = "Https"
      ssl_certificate_name           = var.ssl_certificate_name
      firewall_policy_id             = azurerm_web_application_firewall_policy.main.id
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.key_vault_secret_id != null ? [1] : []
    content {
      name                = var.ssl_certificate_name
      key_vault_secret_id = var.key_vault_secret_id
    }
  }

  # HTTP→HTTPS redirect only makes sense when a TLS certificate is configured.
  # Without one, route HTTP directly to the backend to avoid an infinite redirect loop.
  dynamic "redirect_configuration" {
    for_each = var.ssl_certificate_name != null ? [1] : []
    content {
      name                 = local.redirect_name
      redirect_type        = "Permanent"
      target_listener_name = local.https_listener_name
      include_path         = true
      include_query_string = true
    }
  }

  request_routing_rule {
    name                        = var.ssl_certificate_name != null ? "http-to-https-redirect" : "http-to-backend"
    rule_type                   = "Basic"
    priority                    = 10
    http_listener_name          = local.http_listener_name
    redirect_configuration_name = var.ssl_certificate_name != null ? local.redirect_name : null
    backend_address_pool_name   = var.ssl_certificate_name == null ? local.backend_pool_name : null
    backend_http_settings_name  = var.ssl_certificate_name == null ? local.http_setting_name : null
  }

  dynamic "request_routing_rule" {
    for_each = var.ssl_certificate_name != null ? [1] : []
    content {
      name                       = "https-routing"
      rule_type                  = "Basic"
      priority                   = 20
      http_listener_name         = local.https_listener_name
      backend_address_pool_name  = local.backend_pool_name
      backend_http_settings_name = local.http_setting_name
    }
  }

  tags = var.tags

  # AGIC manages backend pools, listeners,
  # routing rules, and probes — ignore drift from those fields
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      probe,
      redirect_configuration,
      url_path_map,
      ssl_certificate,
      frontend_port,
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.prefix}-agw-diag"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayPerformanceLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }
  enabled_metric { category = "AllMetrics" }
}
