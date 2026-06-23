variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "administrator_object_id" {
  description = "Object ID that receives Key Vault Administrator."
  type        = string
}

variable "administrator_principal_type" {
  description = "Principal type for administrator_object_id."
  type        = string
  default     = "User"

  validation {
    condition     = contains(["User", "Group", "ServicePrincipal"], var.administrator_principal_type)
    error_message = "administrator_principal_type must be User, Group, or ServicePrincipal."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
