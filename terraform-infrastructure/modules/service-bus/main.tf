resource "azurerm_servicebus_namespace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Standard"
  minimum_tls_version           = "1.2"
  local_auth_enabled            = false
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_servicebus_queue" "this" {
  name                                    = var.queue_name
  namespace_id                            = azurerm_servicebus_namespace.this.id
  max_delivery_count                      = 10
  lock_duration                           = "PT1M"
  default_message_ttl                     = "P14D"
  dead_lettering_on_message_expiration    = true
  duplicate_detection_history_time_window = "PT10M"
  requires_duplicate_detection            = true
  partitioning_enabled                    = true
}