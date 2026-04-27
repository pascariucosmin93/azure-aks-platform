variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
    # Set to true for subnets that must not have an NSG (e.g. AzureFirewallSubnet)
    skip_nsg = optional(bool, false)
    # Service delegation (required for PostgreSQL Flexible Server, App Service, etc.)
    delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
}

variable "remote_virtual_network_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
