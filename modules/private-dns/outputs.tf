output "zone_ids" {
  description = "Map of DNS zone name → resource ID"
  value       = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}
