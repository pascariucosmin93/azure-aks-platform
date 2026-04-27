output "firewall_id" {
  value = azurerm_firewall.main.id
}

output "private_ip_address" {
  value = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  value = azurerm_public_ip.firewall.ip_address
}

output "route_table_id" {
  value = azurerm_route_table.aks_egress.id
}
