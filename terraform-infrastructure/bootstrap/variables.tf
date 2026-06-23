variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = "thanu-rg"
}

variable "storage_account_name" {
  type    = string
  default = "storageaccounttaa"
}

variable "container_name" {
  type    = string
  default = "container"
}

variable "state_key" {
  type    = string
  default = "platform.prod.tfstate"
}
