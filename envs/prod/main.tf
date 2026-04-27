data "azurerm_client_config" "current" {}

# ─── Resource Groups ─────────────────────────────────────────────────────────

module "rg_hub" {
  source   = "../../modules/resource-group"
  name     = "${var.prefix}-hub-rg"
  location = var.location
  tags     = var.tags
}

module "rg_spoke" {
  source   = "../../modules/resource-group"
  name     = "${var.prefix}-aks-rg"
  location = var.location
  tags     = var.tags
}

# ─── Networking ──────────────────────────────────────────────────────────────

module "hub_network" {
  source              = "../../modules/network"
  name                = "${var.prefix}-hub-vnet"
  location            = var.location
  resource_group_name = module.rg_hub.name
  address_space       = var.hub_address_space
  subnets             = var.hub_subnets
  tags                = var.tags
}

module "spoke_network" {
  source                    = "../../modules/network"
  name                      = "${var.prefix}-aks-vnet"
  location                  = var.location
  resource_group_name       = module.rg_spoke.name
  address_space             = var.spoke_address_space
  remote_virtual_network_id = module.hub_network.vnet_id
  subnets                   = var.spoke_subnets
  tags                      = var.tags
}

# Hub → Spoke peering (spoke → hub handled by module.spoke_network)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "${var.prefix}-hub-to-spoke"
  resource_group_name          = module.rg_hub.name
  virtual_network_name         = module.hub_network.vnet_name
  remote_virtual_network_id    = module.spoke_network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# ─── Monitoring ───────────────────────────────────────────────────────────────

module "monitoring" {
  source              = "../../modules/monitoring"
  name                = "${var.prefix}-log"
  location            = var.location
  resource_group_name = module.rg_spoke.name
  retention_in_days   = 30
  alert_email         = var.alert_email
  tags                = var.tags
}

# AKS metric alerts — created after AKS to avoid a circular dependency
# (AKS needs workspace ID; alerts need cluster ID)
resource "azurerm_monitor_metric_alert" "aks_node_cpu" {
  count               = var.alert_email != null ? 1 : 0
  name                = "${var.prefix}-aks-node-cpu"
  resource_group_name = module.rg_spoke.name
  scopes              = [module.aks.id]
  description         = "Node CPU above 85% for 15 minutes"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action { action_group_id = module.monitoring.action_group_id }
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "aks_node_memory" {
  count               = var.alert_email != null ? 1 : 0
  name                = "${var.prefix}-aks-node-memory"
  resource_group_name = module.rg_spoke.name
  scopes              = [module.aks.id]
  description         = "Node memory above 85% for 15 minutes"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action { action_group_id = module.monitoring.action_group_id }
  tags = var.tags
}

# ─── Identities ───────────────────────────────────────────────────────────────

module "identity" {
  source              = "../../modules/identity"
  name                = "${var.prefix}-aks-uami"
  location            = var.location
  resource_group_name = module.rg_spoke.name
  tags                = var.tags
}

# Separate identity for Application Gateway (reads TLS certs from Key Vault)
module "agw_identity" {
  source              = "../../modules/identity"
  name                = "${var.prefix}-agw-uami"
  location            = var.location
  resource_group_name = module.rg_spoke.name
  tags                = var.tags
}

# ─── ACR ─────────────────────────────────────────────────────────────────────

module "acr" {
  source                        = "../../modules/acr"
  name                          = replace("${var.prefix}${var.acr_name_suffix}", "-", "")
  location                      = var.location
  resource_group_name           = module.rg_spoke.name
  sku                           = var.acr_sku
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = true
  georeplication_locations      = var.acr_georeplication_locations
  tags                          = var.tags
}

# ─── Key Vault ────────────────────────────────────────────────────────────────

module "key_vault" {
  source                        = "../../modules/key-vault"
  name                          = "${var.prefix}-kv-prod"
  location                      = var.location
  resource_group_name           = module.rg_spoke.name
  tenant_id                     = var.tenant_id
  public_network_access_enabled = false
  log_analytics_workspace_id    = module.monitoring.id
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = [module.spoke_network.subnet_ids["aks"]]
  }
  tags = var.tags
}

# Terraform runner needs Secrets Officer to write the pg password secret.
# This grants it only on this vault, not subscription-wide.
module "terraform_kv_secrets_officer" {
  source               = "../../modules/role-assignment"
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ─── Private DNS Zones ────────────────────────────────────────────────────────

module "private_dns" {
  source              = "../../modules/private-dns"
  resource_group_name = module.rg_hub.name
  dns_zone_names = [
    "privatelink.azurecr.io",
    "privatelink.vaultcore.azure.net",
    "privatelink.redis.cache.windows.net",
  ]
  virtual_network_ids = [
    module.hub_network.vnet_id,
    module.spoke_network.vnet_id,
  ]
  tags = var.tags
}

# ─── Azure Bastion ────────────────────────────────────────────────────────────

module "bastion" {
  source              = "../../modules/bastion"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.rg_hub.name
  subnet_id           = module.hub_network.subnet_ids["AzureBastionSubnet"]
  sku                 = "Standard"
  tags                = var.tags
}

# ─── Azure Firewall ───────────────────────────────────────────────────────────

module "firewall" {
  source                     = "../../modules/firewall"
  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = module.rg_hub.name
  firewall_subnet_id         = module.hub_network.subnet_ids["AzureFirewallSubnet"]
  aks_subnet_cidrs           = var.spoke_subnets["aks"].address_prefixes
  log_analytics_workspace_id = module.monitoring.id
  tags                       = var.tags
}

# Route table must be associated with the AKS subnet before cluster creation
resource "azurerm_subnet_route_table_association" "aks_to_fw" {
  subnet_id      = module.spoke_network.subnet_ids["aks"]
  route_table_id = module.firewall.route_table_id
}

# ─── Application Gateway (WAF v2) ─────────────────────────────────────────────

module "app_gateway" {
  source                     = "../../modules/app-gateway"
  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = module.rg_spoke.name
  subnet_id                  = module.spoke_network.subnet_ids["app-gateway"]
  identity_id                = module.agw_identity.id
  log_analytics_workspace_id = module.monitoring.id
  tags                       = var.tags
}

# ─── Azure Front Door (CDN + Global WAF) ──────────────────────────────────────

module "front_door" {
  source              = "../../modules/front-door"
  prefix              = var.prefix
  resource_group_name = module.rg_spoke.name
  origin_host_name    = module.app_gateway.public_ip_address
  tags                = var.tags
}

# ─── AKS Cluster ─────────────────────────────────────────────────────────────

module "aks" {
  source                          = "../../modules/aks"
  name                            = "${var.prefix}-${var.aks_name_suffix}"
  location                        = var.location
  resource_group_name             = module.rg_spoke.name
  dns_prefix                      = var.dns_prefix
  sku_tier                        = var.aks_sku_tier
  node_subnet_id                  = module.spoke_network.subnet_ids["aks"]
  user_assigned_identity_id       = module.identity.id
  log_analytics_workspace_id      = module.monitoring.id
  pod_cidr                        = var.pod_cidr
  service_cidr                    = var.service_cidr
  dns_service_ip                  = var.dns_service_ip
  private_cluster_enabled         = true
  api_server_authorized_ip_ranges = []
  outbound_type                   = "userDefinedRouting"
  default_node_pool               = var.default_node_pool
  extra_node_pools                = var.extra_node_pools
  tags                            = var.tags

  # Firewall route table must be associated before cluster creation
  depends_on = [azurerm_subnet_route_table_association.aks_to_fw]
}

# ─── Redis Cache ──────────────────────────────────────────────────────────────

module "redis" {
  source                     = "../../modules/redis"
  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = module.rg_spoke.name
  sku_name                   = var.redis_sku_name
  capacity                   = var.redis_capacity
  private_endpoint_subnet_id = module.spoke_network.subnet_ids["private-endpoints"]
  private_dns_zone_id        = module.private_dns.zone_ids["privatelink.redis.cache.windows.net"]
  tags                       = var.tags
}

# ─── PostgreSQL Flexible Server ───────────────────────────────────────────────

resource "random_password" "pg_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "azurerm_key_vault_secret" "pg_admin_password" {
  name         = "pg-admin-password"
  value        = random_password.pg_admin.result
  key_vault_id = module.key_vault.id

  depends_on = [module.terraform_kv_secrets_officer]
}

module "postgresql" {
  source              = "../../modules/postgresql"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.rg_spoke.name
  virtual_network_id  = module.spoke_network.vnet_id
  delegated_subnet_id = module.spoke_network.subnet_ids["postgresql"]
  tenant_id           = var.tenant_id
  sku_name            = var.pg_sku_name
  storage_mb          = var.pg_storage_mb

  administrator_login    = "psqladmin"
  administrator_password = random_password.pg_admin.result

  tags = var.tags
}

# ─── Private Endpoints (ACR & Key Vault) ─────────────────────────────────────

resource "azurerm_private_endpoint" "acr" {
  name                = "${var.prefix}-acr-pe"
  resource_group_name = module.rg_spoke.name
  location            = var.location
  subnet_id           = module.spoke_network.subnet_ids["private-endpoints"]

  private_service_connection {
    name                           = "${var.prefix}-acr-psc"
    private_connection_resource_id = module.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-group"
    private_dns_zone_ids = [module.private_dns.zone_ids["privatelink.azurecr.io"]]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "${var.prefix}-kv-pe"
  resource_group_name = module.rg_spoke.name
  location            = var.location
  subnet_id           = module.spoke_network.subnet_ids["private-endpoints"]

  private_service_connection {
    name                           = "${var.prefix}-kv-psc"
    private_connection_resource_id = module.key_vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-group"
    private_dns_zone_ids = [module.private_dns.zone_ids["privatelink.vaultcore.azure.net"]]
  }

  tags = var.tags
}

# ─── RBAC Role Assignments ────────────────────────────────────────────────────

module "aks_acr_pull" {
  source               = "../../modules/role-assignment"
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

module "aks_key_vault_secrets_user" {
  source               = "../../modules/role-assignment"
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.identity.principal_id
}

# Application Gateway identity reads TLS certs from Key Vault
module "agw_key_vault_secrets_user" {
  source               = "../../modules/role-assignment"
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.agw_identity.principal_id
}
