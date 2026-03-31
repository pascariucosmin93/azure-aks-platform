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
  address_space       = ["10.110.0.0/16"]
  subnets = {
    AzureBastionSubnet = {
      address_prefixes = ["10.110.1.0/24"]
    }
    shared-services = {
      address_prefixes = ["10.110.2.0/24"]
    }
  }
  tags = var.tags
}

module "spoke_network" {
  source                    = "../../modules/network"
  name                      = "${var.prefix}-aks-vnet"
  location                  = var.location
  resource_group_name       = module.rg_spoke.name
  address_space             = ["10.120.0.0/16"]
  remote_virtual_network_id = module.hub_network.vnet_id
  subnets = {
    aks = {
      address_prefixes = ["10.120.1.0/24"]
    }
  }
  tags = var.tags
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
  source              = "../../modules/acr"
  name                = replace("${var.prefix}acrprod", "-", "")
  location            = var.location
  resource_group_name = module.rg_spoke.name
  sku                 = "Premium"
  admin_enabled       = false
  tags                = var.tags
}

module "key_vault" {
  source                        = "../../modules/key-vault"
  name                          = "${var.prefix}-kv-prod"
  location                      = var.location
  resource_group_name           = module.rg_spoke.name
  tenant_id                     = var.tenant_id
  public_network_access_enabled = false
  tags                          = var.tags
}

module "aks" {
  source                          = "../../modules/aks"
  name                            = "${var.prefix}-aks-prod"
  location                        = var.location
  resource_group_name             = module.rg_spoke.name
  dns_prefix                      = "${var.prefix}-aks-prod"
  sku_tier                        = "Standard"
  node_subnet_id                  = module.spoke_network.subnet_ids["aks"]
  user_assigned_identity_id       = module.identity.id
  log_analytics_workspace_id      = module.monitoring.id
  pod_cidr                        = "10.250.0.0/16"
  service_cidr                    = "10.100.0.0/16"
  dns_service_ip                  = "10.100.0.10"
  private_cluster_enabled         = true
  api_server_authorized_ip_ranges = []
  default_node_pool = {
    name            = "system"
    vm_size         = "Standard_D4s_v5"
    node_count      = 3
    os_disk_size_gb = 128
  }
  tags = var.tags
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
