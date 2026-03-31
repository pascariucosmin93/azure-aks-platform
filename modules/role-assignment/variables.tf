variable "scope" {
  type        = string
  description = "Azure scope for the role assignment"
}

variable "role_definition_name" {
  type        = string
  description = "Built-in role definition name"
}

variable "principal_id" {
  type        = string
  description = "Principal object ID"
}
