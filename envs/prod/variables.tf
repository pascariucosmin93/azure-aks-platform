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

variable "tags" {
  type = map(string)
  default = {
    environment = "prod"
    managed_by  = "terraform"
    platform    = "aks"
  }
}

