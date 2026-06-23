output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  value = {
    aks                 = azurerm_subnet.aks.id
    application_gateway = azurerm_subnet.application_gateway.id
    database            = azurerm_subnet.database.id
    private_endpoint    = azurerm_subnet.private_endpoint.id
    vm                  = azurerm_subnet.vm.id
  }
}
