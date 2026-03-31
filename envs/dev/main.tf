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
  address_space       = ["10.10.0.0/16"]
  subnets = {
    AzureBastionSubnet = {
      address_prefixes = ["10.10.1.0/24"]
    }
    shared-services = {
      address_prefixes = ["10.10.2.0/24"]
    }
  }
  tags = var.tags
}

module "spoke_network" {
  source                    = "../../modules/network"
  name                      = "${var.prefix}-aks-vnet"
  location                  = var.location
  resource_group_name       = module.rg_spoke.name
  address_space             = ["10.20.0.0/16"]
  remote_virtual_network_id = module.hub_network.vnet_id
  subnets = {
    aks = {
      address_prefixes = ["10.20.1.0/24"]
    }
  }
  tags = var.tags
}

module "monitoring" {
  source              = "../../modules/monitoring"
  name                = "${var.prefix}-log"
  location            = var.location
  resource_group_name = module.rg_spoke.name
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
  name                = replace("${var.prefix}acrdev", "-", "")
  location            = var.location
  resource_group_name = module.rg_spoke.name
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

module "key_vault" {
  source                        = "../../modules/key-vault"
  name                          = "${var.prefix}-kv-dev"
  location                      = var.location
  resource_group_name           = module.rg_spoke.name
  tenant_id                     = var.tenant_id
  public_network_access_enabled = true
  tags                          = var.tags
}

module "aks" {
  source                     = "../../modules/aks"
  name                       = "${var.prefix}-aks-dev"
  location                   = var.location
  resource_group_name        = module.rg_spoke.name
  dns_prefix                 = "${var.prefix}-aks-dev"
  node_subnet_id             = module.spoke_network.subnet_ids["aks"]
  user_assigned_identity_id  = module.identity.id
  log_analytics_workspace_id = module.monitoring.id
  pod_cidr                   = "10.244.0.0/16"
  service_cidr               = "10.96.0.0/16"
  dns_service_ip             = "10.96.0.10"
  default_node_pool = {
    name            = "system"
    vm_size         = "Standard_D4s_v5"
    node_count      = 2
    os_disk_size_gb = 128
  }
  tags = var.tags
}

