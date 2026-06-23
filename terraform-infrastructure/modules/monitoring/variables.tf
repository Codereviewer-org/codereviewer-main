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

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address, for example name@example.com."
  }
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
  type     = string
  nullable = true
  default  = null
}

variable "vm_alert_enabled" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
