output "resource_group_name" {
  value = data.azurerm_resource_group.platform.name
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "aks_name" {
  value = module.aks.name
}

output "aks_private_fqdn" {
  value = module.aks.private_fqdn
}

output "aks_key_vault_csi_client_id" {
  value = module.aks.key_vault_csi_client_id
}

output "application_gateway_public_ip" {
  value = module.application_gateway.public_ip_address
}

output "acr_name" {
  value = module.container_registry.name
}

output "acr_login_server" {
  value = module.container_registry.login_server
}

output "key_vault_name" {
  value = module.key_vault.name
}

output "postgresql_fqdn" {
  value = module.postgresql.fqdn
}

output "postgresql_database_name" {
  value = module.postgresql.database_name
}

output "service_bus_namespace" {
  value = module.service_bus.name
}

output "service_bus_queue" {
  value = module.service_bus.queue_name
}

output "service_bus_endpoint" {
  value = module.service_bus.endpoint
}

output "vm_name" {
  value = module.linux_vm.name
}

output "vm_public_ip_address" {
  value = module.linux_vm.public_ip_address
}

output "vm_private_ip_address" {
  value = module.linux_vm.private_ip_address
}

output "terraform_state_storage_account" {
  value = data.azurerm_storage_account.terraform_state.name
}
