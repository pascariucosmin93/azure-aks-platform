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

variable "tags" {
  type        = map(string)
  description = "Common resource tags"
  default = {
    environment = "dev"
    managed_by  = "terraform"
    platform    = "aks"
  }
}

