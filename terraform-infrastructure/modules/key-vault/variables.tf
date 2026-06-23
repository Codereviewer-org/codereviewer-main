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

variable "tags" {
  type    = map(string)
  default = {}
}
