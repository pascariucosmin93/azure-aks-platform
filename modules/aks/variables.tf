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
  default = "Standard"
}

variable "private_cluster_enabled" {
  type    = bool
  default = false
}

variable "azure_policy_enabled" {
  type    = bool
  default = true
}

variable "oidc_issuer_enabled" {
  type    = bool
  default = true
}

variable "workload_identity_enabled" {
  type    = bool
  default = true
}

variable "api_server_authorized_ip_ranges" {
  type    = list(string)
  default = []
}

variable "automatic_upgrade_channel" {
  type    = string
  default = "patch"
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
    name                         = string
    vm_size                      = string
    node_count                   = optional(number, 1)
    min_count                    = optional(number, null)
    max_count                    = optional(number, null)
    os_disk_size_gb              = number
    max_pods                     = optional(number, 50)
    only_critical_addons_enabled = optional(bool, true)
    os_disk_type                 = optional(string, "Ephemeral")
    host_encryption_enabled      = optional(bool, true)
  })
}

variable "disk_encryption_set_id" {
  type    = string
  default = null
}

variable "outbound_type" {
  type        = string
  default     = "loadBalancer"
  description = "Use 'userDefinedRouting' when Azure Firewall handles egress"
}

variable "extra_node_pools" {
  description = "Additional node pools beyond the system pool"
  type = map(object({
    vm_size         = string
    min_count       = number
    max_count       = number
    max_pods        = optional(number, 50)
    os_disk_size_gb = optional(number, 128)
    os_disk_type    = optional(string, "Ephemeral")
    node_labels     = optional(map(string), {})
    node_taints     = optional(list(string), [])
    priority        = optional(string, "Regular")
    spot_max_price  = optional(number, -1)
    zones           = optional(list(string), ["1", "2", "3"])
    mode            = optional(string, "User")
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
