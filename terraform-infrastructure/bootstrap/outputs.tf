output "resource_group_name" {
  value = data.azurerm_resource_group.backend.name
}

output "storage_account_name" {
  value = data.azurerm_storage_account.backend.name
}

output "container_name" {
  value = var.container_name
}

output "backend_hcl" {
  value = <<-EOT
    resource_group_name  = "${data.azurerm_resource_group.backend.name}"
    storage_account_name = "${data.azurerm_storage_account.backend.name}"
    container_name       = "${var.container_name}"
    key                  = "${var.state_key}"
    use_azuread_auth     = true
  EOT
}
