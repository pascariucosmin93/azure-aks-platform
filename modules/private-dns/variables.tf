variable "resource_group_name" {
  type = string
}

variable "dns_zone_names" {
  type        = list(string)
  description = "Private DNS zone names to create (e.g. privatelink.azurecr.io)"
}

variable "virtual_network_ids" {
  type        = list(string)
  description = "VNet IDs to link to every created DNS zone"
}

variable "tags" {
  type    = map(string)
  default = {}
}
