variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "ID of the AzureBastionSubnet (must be /26 or larger)"
}

variable "sku" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be Basic or Standard"
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
