provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

data "azurerm_resource_group" "backend" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "backend" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.backend.name
}
