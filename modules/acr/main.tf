resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  quarantine_policy_enabled     = var.quarantine_policy_enabled
  export_policy_enabled         = var.export_policy_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option
  retention_policy_in_days      = var.retention_policy_enabled ? var.retention_policy_days : null
  trust_policy_enabled          = contains(["Premium"], var.sku) ? true : null
  tags                          = var.tags

  dynamic "georeplications" {
    for_each = contains(["Premium"], var.sku) ? toset(var.georeplication_locations) : []
    content {
      location                  = georeplications.value
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = true
      tags                      = var.tags
    }
  }
}
