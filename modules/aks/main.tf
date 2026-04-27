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
    auto_scaling_enabled         = var.default_node_pool.min_count != null
    node_count                   = var.default_node_pool.node_count
    min_count                    = var.default_node_pool.min_count
    max_count                    = var.default_node_pool.max_count
    vnet_subnet_id               = var.node_subnet_id
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    max_pods                     = var.default_node_pool.max_pods
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled
    os_disk_type                 = var.default_node_pool.os_disk_type
    host_encryption_enabled      = var.default_node_pool.host_encryption_enabled
    type                         = "VirtualMachineScaleSets"
    zones                        = ["1", "2", "3"]
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
    outbound_type       = var.outbound_type
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    start_time  = "01:00"
    utc_offset  = "+00:00"
    duration    = 4
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    start_time  = "03:00"
    utc_offset  = "+00:00"
    duration    = 4
  }

  role_based_access_control_enabled = true
  local_account_disabled            = true

  disk_encryption_set_id = var.disk_encryption_set_id
}

resource "azurerm_kubernetes_cluster_node_pool" "extra" {
  for_each = var.extra_node_pools

  name                    = each.key
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.this.id
  vm_size                 = each.value.vm_size
  auto_scaling_enabled    = true
  min_count               = each.value.min_count
  max_count               = each.value.max_count
  max_pods                = coalesce(each.value.max_pods, 50)
  os_disk_size_gb         = each.value.os_disk_size_gb
  os_disk_type            = each.value.os_disk_type
  host_encryption_enabled = coalesce(each.value.host_encryption_enabled, true)
  vnet_subnet_id          = var.node_subnet_id
  node_labels             = each.value.node_labels
  node_taints             = each.value.node_taints
  priority                = each.value.priority
  eviction_policy         = each.value.priority == "Spot" ? "Delete" : null
  spot_max_price          = each.value.priority == "Spot" ? each.value.spot_max_price : null
  zones                   = each.value.zones
  mode                    = each.value.mode
  tags                    = var.tags
}
