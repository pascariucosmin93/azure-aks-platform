variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "virtual_network_id" {
  type        = string
  description = "VNet ID to link the private DNS zone to"
}

variable "delegated_subnet_id" {
  type        = string
  description = "Subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers"
}

variable "tenant_id" {
  type = string
}

variable "postgresql_version" {
  type    = string
  default = "16"
}

variable "administrator_login" {
  type    = string
  default = "psqladmin"
}

variable "administrator_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "backup_retention_days" {
  type    = number
  default = 14
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}

variable "high_availability_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
