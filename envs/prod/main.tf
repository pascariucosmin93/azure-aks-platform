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

module "monitoring" {
  source              = "../../modules/monitoring"
  name                = "${var.prefix}-log"
  location            = var.location
  resource_group_name = module.rg_spoke.name
  retention_in_days   = 30
  tags                = var.tags
}

module "identity" {
  source              = "../../modules/identity"
  name                = "${var.prefix}-aks-uami"
  location            = var.location
  resource_group_name = module.rg_spoke.name
  tags                = var.tags
}

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

module "key_vault" {
  source                        = "../../modules/key-vault"
  name                          = "${var.prefix}-kv-prod"
  location                      = var.location
  resource_group_name           = module.rg_spoke.name
  tenant_id                     = var.tenant_id
  public_network_access_enabled = false
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = [module.spoke_network.subnet_ids["aks"]]
  }
  tags = var.tags
}

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
  default_node_pool               = var.default_node_pool
  tags                            = var.tags
}

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
