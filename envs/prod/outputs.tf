output "aks_name" {
  value = module.aks.name
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "key_vault_name" {
  value = module.key_vault.name
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "app_gateway_public_ip" {
  value = module.app_gateway.public_ip_address
}

output "front_door_endpoint" {
  value = module.front_door.endpoint_hostname
}

output "bastion_dns_name" {
  value = module.bastion.dns_name
}

output "firewall_public_ip" {
  value = module.firewall.public_ip_address
}

output "redis_hostname" {
  value = module.redis.hostname
}

output "postgresql_fqdn" {
  value = module.postgresql.fqdn
}

output "log_analytics_workspace_id" {
  value = module.monitoring.workspace_id
}
