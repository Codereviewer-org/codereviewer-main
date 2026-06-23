variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "application_gateway_id" {
  type = string
}

variable "application_gateway_subnet_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "system_node_min_count" {
  type    = number
  default = 1
}

variable "system_node_max_count" {
  type    = number
  default = 1
}

variable "workload_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "workload_node_min_count" {
  type    = number
  default = 0
}

variable "workload_node_max_count" {
  type    = number
  default = 1
}

variable "zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "pod_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "service_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "10.0.0.10"
}

variable "tags" {
  type    = map(string)
  default = {}
}
