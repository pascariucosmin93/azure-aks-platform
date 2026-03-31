module "rg" {
  source   = "../../modules/resource-group"
  name     = "${var.prefix}-rg"
  location = var.location
}

module "network" {
  source              = "../../modules/network"
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = module.rg.name
  address_space       = ["10.30.0.0/16"]
  subnets = {
    aks = {
      address_prefixes = ["10.30.1.0/24"]
    }
  }
}

module "monitoring" {
  source              = "../../modules/monitoring"
  name                = "${var.prefix}-log"
  location            = var.location
  resource_group_name = module.rg.name
}

module "identity" {
  source              = "../../modules/identity"
  name                = "${var.prefix}-uami"
  location            = var.location
  resource_group_name = module.rg.name
}

module "aks" {
  source                     = "../../modules/aks"
  name                       = "${var.prefix}-aks"
  location                   = var.location
  resource_group_name        = module.rg.name
  dns_prefix                 = "${var.prefix}-aks"
  node_subnet_id             = module.network.subnet_ids["aks"]
  user_assigned_identity_id  = module.identity.id
  log_analytics_workspace_id = module.monitoring.id
  pod_cidr                   = "10.240.0.0/16"
  service_cidr               = "10.241.0.0/16"
  dns_service_ip             = "10.241.0.10"
  default_node_pool = {
    name            = "system"
    vm_size         = "Standard_D4s_v5"
    node_count      = 1
    os_disk_size_gb = 128
  }
}
