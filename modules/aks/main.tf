resource "azurerm_kubernetes_cluster" "this" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = var.dns_prefix
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = var.sku_tier
  private_cluster_enabled   = var.private_cluster_enabled
  azure_policy_enabled      = var.azure_policy_enabled
  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled
  automatic_upgrade_channel = var.automatic_upgrade_channel
  tags                      = var.tags

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    node_count                   = var.default_node_pool.node_count
    vnet_subnet_id               = var.node_subnet_id
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    max_pods                     = var.default_node_pool.max_pods
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled
    os_disk_type                 = var.default_node_pool.os_disk_type
    host_encryption_enabled      = var.default_node_pool.host_encryption_enabled
    type                         = "VirtualMachineScaleSets"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  role_based_access_control_enabled = true
  local_account_disabled            = true

  disk_encryption_set_id = var.disk_encryption_set_id
}
