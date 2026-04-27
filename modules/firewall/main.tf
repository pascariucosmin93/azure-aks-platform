resource "azurerm_public_ip" "firewall" {
  name                = "${var.prefix}-fw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall_policy" "main" {
  name                = "${var.prefix}-fw-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku_tier

  dns {
    proxy_enabled = true
  }

  tags = var.tags
}

resource "azurerm_firewall" "main" {
  name                = "${var.prefix}-fw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.main.id
  zones               = ["1", "2", "3"]

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "aks" {
  name               = "aks-egress-rules"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  network_rule_collection {
    name     = "aks-required-network"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-ntp"
      protocols             = ["UDP"]
      source_addresses      = var.aks_subnet_cidrs
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    rule {
      name                  = "allow-dns"
      protocols             = ["UDP", "TCP"]
      source_addresses      = var.aks_subnet_cidrs
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "allow-azure-services"
      protocols             = ["TCP"]
      source_addresses      = var.aks_subnet_cidrs
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "allow-azure-monitor"
      protocols             = ["TCP"]
      source_addresses      = var.aks_subnet_cidrs
      destination_addresses = ["AzureMonitor"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "allow-aad"
      protocols             = ["TCP"]
      source_addresses      = var.aks_subnet_cidrs
      destination_addresses = ["AzureActiveDirectory"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "allow-tunnelfront"
      protocols             = ["TCP", "UDP"]
      source_addresses      = var.aks_subnet_cidrs
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["9000", "1194"]
    }
  }

  application_rule_collection {
    name     = "aks-required-fqdns"
    priority = 200
    action   = "Allow"

    rule {
      name             = "allow-aks-dependencies"
      source_addresses = var.aks_subnet_cidrs
      destination_fqdns = [
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
        "dc.services.visualstudio.com",
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com",
      ]
      protocols {
        port = "443"
        type = "Https"
      }
    }

    rule {
      name             = "allow-ubuntu-updates"
      source_addresses = var.aks_subnet_cidrs
      destination_fqdns = [
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com",
      ]
      protocols {
        port = "80"
        type = "Http"
      }
    }
  }
}

resource "azurerm_route_table" "aks_egress" {
  name                          = "${var.prefix}-aks-egress-rt"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = false
  tags                          = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.prefix}-fw-diag"
  target_resource_id         = azurerm_firewall.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }
  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_route" "internet_via_firewall" {
  name                   = "internet-via-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.aks_egress.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
}
