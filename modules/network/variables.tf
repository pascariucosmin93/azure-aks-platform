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

