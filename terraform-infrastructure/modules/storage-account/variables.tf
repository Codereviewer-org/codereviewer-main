variable "name" {
  description = "Globally unique lowercase storage account name."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_names" {
  description = "Private blob containers to create."
  type        = set(string)
  default     = ["tfstate"]
}

variable "replication_type" {
  type    = string
  default = "ZRS"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "blob_data_contributor_object_ids" {
  description = "Principal object IDs allowed to use the private state container with Microsoft Entra authentication."
  type        = set(string)
  default     = []
}
