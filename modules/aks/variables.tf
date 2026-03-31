variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "sku_tier" {
  type    = string
  default = "Free"
}

variable "node_subnet_id" {
  type = string
}

variable "user_assigned_identity_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "pod_cidr" {
  type = string
}

variable "service_cidr" {
  type = string
}

variable "dns_service_ip" {
  type = string
}

variable "default_node_pool" {
  type = object({
    name            = string
    vm_size         = string
    node_count      = number
    os_disk_size_gb = number
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}

