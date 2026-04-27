resource "azurerm_private_dns_zone" "zones" {
  for_each = toset(var.dns_zone_names)

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  # Cartesian product: every zone × every VNet
  zone_vnet_pairs = flatten([
    for zone in var.dns_zone_names : [
      for idx, vnet_id in var.virtual_network_ids : {
        key     = "${replace(zone, ".", "-")}-${idx}"
        zone    = zone
        vnet_id = vnet_id
      }
    ]
  ])
}

resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = { for pair in local.zone_vnet_pairs : pair.key => pair }

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.value.zone].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}
