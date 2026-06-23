variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "location" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "aks_id" {
  type = string
}

variable "postgresql_id" {
  type = string
}

variable "application_gateway_id" {
  type = string
}

variable "service_bus_id" {
  type = string
}

variable "vm_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
