variable "name" {
  description = "Linux VM name."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  description = "Subnet used by the VM network interface."
  type        = string
}

variable "admin_username" {
  type    = string
  default = "azure"
}

variable "admin_password" {
  description = "VM administrator password. Pass through TF_VAR_vm_admin_password."
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Ubuntu jumpbox size. This consumes regional compute quota."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "tags" {
  type    = map(string)
  default = {}
}
