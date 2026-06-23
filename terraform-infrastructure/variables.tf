variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group created by the bootstrap stack."
  type        = string
  default     = "rg-codereviewer-platform"
}

variable "terraform_state_storage_account_name" {
  description = "Storage account created by the bootstrap stack."
  type        = string
}

variable "location" {
  description = "Azure region used for the platform."
  type        = string
  default     = "australiaeast"
}

variable "environment" {
  type    = string
  default = "prod"

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "environment must be dev, test, stage, or prod."
  }
}

variable "name_prefix" {
  description = "Short lowercase prefix used in Azure resource names."
  type        = string
  default     = "coderaptor"
}

variable "alert_email" {
  description = "Email address that receives Azure Monitor alerts."
  type        = string
}

variable "postgresql_administrator_login" {
  type    = string
  default = "postgress"
}

variable "postgresql_administrator_password" {
  description = "PostgreSQL administrator password. Pass through TF_VAR or protected CI secret."
  type        = string
  sensitive   = true
}

variable "vm_admin_username" {
  description = "Linux jumpbox administrator username."
  type        = string
  default     = "azure"
}

variable "vm_admin_password" {
  description = "Linux jumpbox administrator password. Pass through TF_VAR_vm_admin_password."
  type        = string
  sensitive   = true
  default     = null
}

variable "vm_size" {
  description = "Ubuntu jumpbox VM size for the quota-constrained demo profile."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "create_jumpbox_vm" {
  description = "Create a Terraform-managed Ubuntu jumpbox."
  type        = bool
  default     = true
}

variable "postgresql_sku_name" {
  type    = string
  default = "GP_Standard_D2s_v3"
}

variable "postgresql_high_availability_enabled" {
  type    = bool
  default = false
}

variable "system_node_vm_size" {
  description = "AKS system pool VM SKU."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "workload_node_vm_size" {
  description = "AKS application pool VM SKU. Default is reduced for a quota-constrained demo profile."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "workload_node_min_count" {
  type    = number
  default = 1
}

variable "workload_node_max_count" {
  type    = number
  default = 1
}

variable "availability_zones" {
  description = "Zones supported by the selected region and VM SKU. Use [] to create non-zonal resources and avoid zone-specific SKU restrictions."
  type        = list(string)
  default     = []
}

variable "acr_public_network_access_enabled" {
  description = "Keep true for GitHub-hosted runners; set false when using a self-hosted runner in the VNet."
  type        = bool
  default     = true
}

variable "admin_source_cidr" {
  description = "Trusted public IPv4 CIDR allowed to SSH to the jumpbox, normally your public IP with /32."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_source_cidr, 0)) && var.admin_source_cidr != "0.0.0.0/0"
    error_message = "admin_source_cidr must be a valid, restricted CIDR and cannot be 0.0.0.0/0."
  }
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.20.0.0/16"]
}

variable "subnet_prefixes" {
  type = object({
    aks                 = list(string)
    application_gateway = list(string)
    database            = list(string)
    private_endpoint    = list(string)
    vm                  = list(string)
  })

  default = {
    aks                 = ["10.20.0.0/21"]
    application_gateway = ["10.20.8.0/24"]
    database            = ["10.20.9.0/24"]
    private_endpoint    = ["10.20.10.0/24"]
    vm                  = ["10.20.11.0/24"]
  }
}

variable "tags" {
  type = map(string)
  default = {
    Application = "CodeRaptor"
    ManagedBy   = "Terraform"
    Owner       = "Platform"
  }
}
