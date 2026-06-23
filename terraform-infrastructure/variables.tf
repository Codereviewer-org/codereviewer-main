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
  description = "Azure region. Central India matches the current platform."
  type        = string
  default     = "centralindia"
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
}

variable "vm_size" {
  description = "Ubuntu jumpbox VM size. Standard_D2s_v5 is broadly available in Central India when DSv5 quota is approved."
  type        = string
  default     = "Standard_D2s_v5"
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
  default     = "Standard_D2s_v5"
}

variable "workload_node_vm_size" {
  description = "AKS application pool VM SKU sized for approximately 20 application pods with rollout headroom."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "workload_node_min_count" {
  type    = number
  default = 2
}

variable "workload_node_max_count" {
  type    = number
  default = 4
}

variable "availability_zones" {
  description = "Zones supported by the selected region and VM SKU. Central India zone 2 is commonly restricted for this subscription, so zones 1 and 3 are safer defaults."
  type        = list(string)
  default     = ["1", "3"]
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
