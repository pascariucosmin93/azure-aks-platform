variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

variable "prefix" {
  type        = string
  description = "Naming prefix"
  default     = "demo"
}

variable "hub_address_space" {
  type        = list(string)
  description = "Hub VNet address space"
  default     = ["10.10.0.0/16"]
}

variable "hub_subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  description = "Hub subnets"
  default = {
    AzureBastionSubnet = {
      address_prefixes = ["10.10.1.0/24"]
    }
    shared-services = {
      address_prefixes = ["10.10.2.0/24"]
    }
  }
}

variable "spoke_address_space" {
  type        = list(string)
  description = "Spoke VNet address space"
  default     = ["10.20.0.0/16"]
}

variable "spoke_subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  description = "Spoke subnets"
  default = {
    aks = {
      address_prefixes = ["10.20.1.0/24"]
    }
  }
}

variable "acr_name_suffix" {
  type        = string
  description = "Suffix used to build the ACR name"
  default     = "acrdev"
}

variable "acr_sku" {
  type        = string
  description = "ACR SKU"
  default     = "Premium"
}

variable "acr_georeplication_locations" {
  type        = list(string)
  description = "Additional ACR georeplication regions"
  default     = ["northeurope"]
}

variable "aks_name_suffix" {
  type        = string
  description = "Suffix used to build the AKS cluster name"
  default     = "aks-dev"
}

variable "dns_prefix" {
  type        = string
  description = "AKS DNS prefix"
  default     = "demo-aks-dev"
}

variable "aks_sku_tier" {
  type        = string
  description = "AKS SKU tier"
  default     = "Standard"
}

variable "pod_cidr" {
  type        = string
  description = "AKS pod CIDR"
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = "AKS service CIDR"
  default     = "10.96.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "AKS DNS service IP"
  default     = "10.96.0.10"
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
  description = "AKS default node pool configuration"
  default = {
    name                         = "system"
    vm_size                      = "Standard_D4s_v5"
    node_count                   = 2
    os_disk_size_gb              = 128
    max_pods                     = 50
    only_critical_addons_enabled = true
    os_disk_type                 = "Ephemeral"
    host_encryption_enabled      = true
  }
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags"
  default = {
    environment = "dev"
    managed_by  = "terraform"
    platform    = "aks"
  }
}
