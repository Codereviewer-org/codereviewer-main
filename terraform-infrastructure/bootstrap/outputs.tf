output "resource_group_name" {
  value = module.resource_group.name
}

output "storage_account_name" {
  value = module.storage_account.name
}

output "container_name" {
  value = "tfstate"
}

output "backend_hcl" {
  value = <<-EOT
    resource_group_name  = "${module.resource_group.name}"
    storage_account_name = "${module.storage_account.name}"
    container_name       = "tfstate"
    key                  = "platform.prod.tfstate"
    use_azuread_auth     = true
  EOT
}
