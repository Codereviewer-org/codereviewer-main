variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "public_network_access_enabled" {
  description = "Keep true for GitHub-hosted runners. Set false when builds run from inside the VNet."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
