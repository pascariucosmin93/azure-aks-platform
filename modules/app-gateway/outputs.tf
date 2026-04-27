output "id" {
  value = azurerm_application_gateway.main.id
}

output "name" {
  value = azurerm_application_gateway.main.name
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

output "waf_policy_id" {
  value = azurerm_web_application_firewall_policy.main.id
}
