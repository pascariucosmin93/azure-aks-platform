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
  description = "Subnet ID for Application Gateway (dedicated subnet, minimum /24)"
}

variable "identity_id" {
  type        = string
  description = "User-assigned managed identity ID (needs 'Key Vault Secrets User' for TLS certs)"
}

variable "ssl_certificate_name" {
  type    = string
  default = null
}

variable "key_vault_secret_id" {
  type        = string
  default     = null
  description = "Key Vault versioned secret URI for the TLS certificate"
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 10
}

variable "waf_mode" {
  type    = string
  default = "Prevention"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be Detection or Prevention"
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
