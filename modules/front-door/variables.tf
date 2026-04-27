variable "prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "origin_host_name" {
  type        = string
  description = "Public IP or hostname of the Application Gateway acting as origin"
}

variable "sku_name" {
  type    = string
  default = "Standard_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be Standard_AzureFrontDoor or Premium_AzureFrontDoor"
  }
}

variable "waf_mode" {
  type    = string
  default = "Prevention"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be Detection or Prevention"
  }
}

variable "health_probe_path" {
  type    = string
  default = "/healthz"
}

variable "tags" {
  type    = map(string)
  default = {}
}
