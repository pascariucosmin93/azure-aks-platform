variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "prefix" {
  type    = string
  default = "prod"
}

variable "hub_address_space" {
  type    = list(string)
  default = ["10.110.0.0/16"]
}

variable "hub_subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    AzureBastionSubnet = {
      address_prefixes = ["10.110.1.0/24"]
    }
    shared-services = {
      address_prefixes = ["10.110.2.0/24"]
    }
  }
}

variable "spoke_address_space" {
  type    = list(string)
  default = ["10.120.0.0/16"]
}

variable "spoke_subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    aks = {
      address_prefixes = ["10.120.1.0/24"]
    }
  }
}

variable "acr_name_suffix" {
  type    = string
  default = "acrprod"
}

variable "acr_sku" {
  type    = string
  default = "Premium"
}

variable "acr_georeplication_locations" {
  type    = list(string)
  default = ["northeurope"]
}

variable "aks_name_suffix" {
  type    = string
  default = "aks-prod"
}

variable "dns_prefix" {
  type    = string
  default = "prod-aks-prod"
}

variable "aks_sku_tier" {
  type    = string
  default = "Standard"
}

variable "pod_cidr" {
  type    = string
  default = "10.250.0.0/16"
}

variable "service_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "10.100.0.10"
}

variable "default_node_pool" {
  type = object({
    name                         = string
    vm_size                      = string
    node_count                   = number
    os_disk_size_gb              = number
    max_pods                     = number
    only_critical_addons_enabled = bool
    os_disk_type                 = string
    host_encryption_enabled      = bool
  })
  default = {
    name                         = "system"
    vm_size                      = "Standard_D4s_v5"
    node_count                   = 3
    os_disk_size_gb              = 128
    max_pods                     = 50
    only_critical_addons_enabled = true
    os_disk_type                 = "Ephemeral"
    host_encryption_enabled      = true
  }
}

variable "tags" {
  type = map(string)
  default = {
    environment = "prod"
    managed_by  = "terraform"
    platform    = "aks"
  }
}
