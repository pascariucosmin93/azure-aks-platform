variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "firewall_subnet_id" {
  type        = string
  description = "ID of AzureFirewallSubnet (must be named exactly 'AzureFirewallSubnet', minimum /26)"
}

variable "aks_subnet_cidrs" {
  type        = list(string)
  description = "AKS subnet CIDRs used as firewall rule source addresses"
}

variable "sku_tier" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Basic, Standard, or Premium"
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log Analytics workspace ID for diagnostic logs"
}

variable "tags" {
  type    = map(string)
  default = {}
}
