variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = "rg-codereviewer-platform"
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "name_prefix" {
  description = "Lowercase alphanumeric prefix for the state storage account."
  type        = string
  default     = "coderaptor"
}

variable "backend_principal_object_id" {
  description = "Optional GitHub Actions or Terraform runner service-principal object ID."
  type        = string
  default     = null
}

variable "tags" {
  type = map(string)
  default = {
    Application = "CodeRaptor"
    Environment = "Shared"
    Owner       = "Platform"
  }
}
