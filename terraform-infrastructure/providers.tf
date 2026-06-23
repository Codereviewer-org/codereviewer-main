provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "platform" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "terraform_state" {
  name                = var.terraform_state_storage_account_name
  resource_group_name = data.azurerm_resource_group.platform.name
}
