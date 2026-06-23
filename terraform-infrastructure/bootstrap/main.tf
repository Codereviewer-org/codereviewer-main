provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 7
  upper   = false
  special = false
}

locals {
  storage_name = substr(replace(lower("${var.name_prefix}tfstate${random_string.suffix.result}"), "/[^0-9a-z]/", ""), 0, 24)
  backend_principals = toset(compact([
    data.azurerm_client_config.current.object_id,
    var.backend_principal_object_id
  ]))

  tags = merge(var.tags, {
    Purpose   = "TerraformState"
    ManagedBy = "Terraform"
  })
}

module "resource_group" {
  source = "../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "storage_account" {
  source = "../modules/storage-account"

  name                             = local.storage_name
  resource_group_name              = module.resource_group.name
  location                         = module.resource_group.location
  container_names                  = ["tfstate"]
  replication_type                 = "ZRS"
  blob_data_contributor_object_ids = local.backend_principals
  tags                             = local.tags
}
