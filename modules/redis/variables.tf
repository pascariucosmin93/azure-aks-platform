variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "sku_name" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name must be Basic, Standard, or Premium"
  }
}

variable "capacity" {
  type        = number
  default     = 1
  description = "SKU size: 0-6 for Basic/Standard, 1-5 for Premium"
}

variable "tags" {
  type    = map(string)
  default = {}
}
