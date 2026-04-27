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

# ─── Networking ─────────────────────────────────────────────────────────────

variable "hub_address_space" {
  type    = list(string)
  default = ["10.110.0.0/16"]
}

variable "hub_subnets" {
  type = map(object({
    address_prefixes = list(string)
    skip_nsg         = optional(bool, false)
    delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
  default = {
    AzureBastionSubnet = {
      address_prefixes = ["10.110.0.0/26"]
      # NSG is managed by the bastion module with the exact rules the service requires
      skip_nsg = true
    }
    AzureFirewallSubnet = {
      address_prefixes = ["10.110.1.0/26"]
      # Azure Firewall does not support an NSG on its subnet
      skip_nsg = true
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
    skip_nsg         = optional(bool, false)
    delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
  default = {
    aks = {
      address_prefixes = ["10.120.1.0/24"]
    }
    app-gateway = {
      address_prefixes = ["10.120.2.0/24"]
    }
    private-endpoints = {
      address_prefixes = ["10.120.3.0/24"]
    }
    postgresql = {
      address_prefixes = ["10.120.4.0/24"]
      delegation = {
        name = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
        ]
      }
    }
  }
}

# ─── ACR ────────────────────────────────────────────────────────────────────

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

# ─── AKS ────────────────────────────────────────────────────────────────────

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
    min_count                    = 3
    max_count                    = 5
    os_disk_size_gb              = 128
    max_pods                     = 50
    only_critical_addons_enabled = true
    os_disk_type                 = "Ephemeral"
    host_encryption_enabled      = true
  }
}

variable "extra_node_pools" {
  type = map(object({
    vm_size                 = string
    min_count               = number
    max_count               = number
    max_pods                = optional(number, 50)
    os_disk_size_gb         = optional(number, 128)
    os_disk_type            = optional(string, "Ephemeral")
    host_encryption_enabled = optional(bool, true)
    node_labels             = optional(map(string), {})
    node_taints             = optional(list(string), [])
    priority                = optional(string, "Regular")
    spot_max_price          = optional(number, -1)
    zones                   = optional(list(string), ["1", "2", "3"])
    mode                    = optional(string, "User")
  }))
  default = {
    workload = {
      vm_size   = "Standard_D4s_v5"
      min_count = 2
      max_count = 10
      mode      = "User"
      node_labels = {
        "workload-type" = "general"
      }
    }
    spot = {
      vm_size        = "Standard_D4s_v5"
      min_count      = 0
      max_count      = 5
      priority       = "Spot"
      spot_max_price = -1
      mode           = "User"
      node_taints    = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
      node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
      }
    }
  }
}

# ─── PostgreSQL ──────────────────────────────────────────────────────────────

variable "pg_sku_name" {
  type    = string
  default = "GP_Standard_D2s_v3"
}

variable "pg_storage_mb" {
  type    = number
  default = 32768
}

# ─── Redis ───────────────────────────────────────────────────────────────────

variable "redis_sku_name" {
  type    = string
  default = "Standard"
}

variable "redis_capacity" {
  type    = number
  default = 1
}

# ─── Observability ───────────────────────────────────────────────────────────

variable "alert_email" {
  type        = string
  default     = null
  description = "Email address for ops metric alerts (CPU/memory thresholds)"
}

# ─── Tags ────────────────────────────────────────────────────────────────────

variable "tags" {
  type = map(string)
  default = {
    environment = "prod"
    managed_by  = "terraform"
    platform    = "aks"
  }
}
