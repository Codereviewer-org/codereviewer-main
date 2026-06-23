resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  normalized_prefix = substr(replace(lower("${var.name_prefix}${var.environment}"), "/[^0-9a-z]/", ""), 0, 13)
  suffix            = random_string.suffix.result
  common_name       = "${var.name_prefix}-${var.environment}"

  names = {
    vnet                = "${local.common_name}-vnet"
    log_analytics       = "${local.common_name}-logs"
    application_gateway = "${local.common_name}-appgw"
    aks                 = "${local.common_name}-aks"
    acr                 = substr("${local.normalized_prefix}acr${local.suffix}", 0, 50)
    key_vault           = substr("${local.common_name}-${local.suffix}-kv", 0, 24)
    postgresql          = substr("${local.common_name}-${local.suffix}-psql", 0, 63)
    service_bus         = substr("${local.common_name}-sb-${local.suffix}", 0, 50)
    vm                  = "${local.common_name}-jumpbox"
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Region      = var.location
  })
}

module "networking" {
  source = "./modules/networking"

  name                = local.names.vnet
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = var.location
  address_space       = var.vnet_address_space
  subnet_prefixes     = var.subnet_prefixes
  admin_source_cidr   = var.admin_source_cidr
  tags                = local.tags
}

module "log_analytics" {
  source = "./modules/log-analytics"

  name                = local.names.log_analytics
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = var.location
  retention_in_days   = 30
  tags                = local.tags
}

module "application_gateway" {
  source = "./modules/application-gateway"

  name                = local.names.application_gateway
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = var.location
  subnet_id           = module.networking.subnet_ids.application_gateway
  capacity_min        = 1
  capacity_max        = 3
  zones               = var.availability_zones
  tags                = local.tags
}

module "container_registry" {
  source = "./modules/container-registry"

  name                          = local.names.acr
  resource_group_name           = data.azurerm_resource_group.platform.name
  location                      = var.location
  private_endpoint_subnet_id    = module.networking.subnet_ids.private_endpoint
  vnet_id                       = module.networking.vnet_id
  public_network_access_enabled = var.acr_public_network_access_enabled
  tags                          = local.tags
}

module "key_vault" {
  source = "./modules/key-vault"

  name                         = local.names.key_vault
  resource_group_name          = data.azurerm_resource_group.platform.name
  location                     = var.location
  tenant_id                    = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet_id   = module.networking.subnet_ids.private_endpoint
  vnet_id                      = module.networking.vnet_id
  administrator_object_id      = data.azurerm_client_config.current.object_id
  administrator_principal_type = "User"
  tags                         = local.tags
}

module "postgresql" {
  source = "./modules/postgresql"

  name                      = local.names.postgresql
  resource_group_name       = data.azurerm_resource_group.platform.name
  location                  = var.location
  delegated_subnet_id       = module.networking.subnet_ids.database
  vnet_id                   = module.networking.vnet_id
  administrator_login       = var.postgresql_administrator_login
  administrator_password    = var.postgresql_administrator_password
  database_name             = "coderaptor"
  sku_name                  = var.postgresql_sku_name
  high_availability_enabled = var.postgresql_high_availability_enabled
  tags                      = local.tags
}

module "service_bus" {
  source = "./modules/service-bus"

  name                = local.names.service_bus
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = var.location
  queue_name          = "review-jobs"
  tags                = local.tags
}

module "linux_vm" {
  count  = var.create_jumpbox_vm ? 1 : 0
  source = "./modules/linux-vm"

  name                = local.names.vm
  resource_group_name = data.azurerm_resource_group.platform.name
  location            = var.location
  subnet_id           = module.networking.subnet_ids.vm
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  vm_size             = var.vm_size
  tags                = local.tags
}

module "aks" {
  source = "./modules/aks"

  name                          = local.names.aks
  resource_group_name           = data.azurerm_resource_group.platform.name
  location                      = var.location
  aks_subnet_id                 = module.networking.subnet_ids.aks
  application_gateway_id        = module.application_gateway.id
  application_gateway_subnet_id = module.networking.subnet_ids.application_gateway
  acr_id                        = module.container_registry.id
  key_vault_id                  = module.key_vault.id
  log_analytics_workspace_id    = module.log_analytics.id
  system_node_vm_size           = var.system_node_vm_size
  workload_node_vm_size         = var.workload_node_vm_size
  workload_node_min_count       = var.workload_node_min_count
  workload_node_max_count       = var.workload_node_max_count
  zones                         = var.availability_zones
  tags                          = local.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix            = local.common_name
  resource_group_name    = data.azurerm_resource_group.platform.name
  resource_group_id      = data.azurerm_resource_group.platform.id
  location               = var.location
  alert_email            = var.alert_email
  aks_id                 = module.aks.id
  postgresql_id          = module.postgresql.id
  application_gateway_id = module.application_gateway.id
  service_bus_id         = module.service_bus.id
  vm_id                  = var.create_jumpbox_vm ? module.linux_vm[0].id : null
  vm_alert_enabled       = var.create_jumpbox_vm
  tags                   = local.tags
}

locals {
  base_diagnostic_targets = {
    aks                 = module.aks.id
    application_gateway = module.application_gateway.id
    acr                 = module.container_registry.id
    key_vault           = module.key_vault.id
    postgresql          = module.postgresql.id
    service_bus         = module.service_bus.id
    storage             = data.azurerm_storage_account.terraform_state.id
  }

  diagnostic_targets = merge(
    local.base_diagnostic_targets,
    var.create_jumpbox_vm ? { vm = module.linux_vm[0].id } : {}
  )
}

module "diagnostics" {
  for_each = local.diagnostic_targets
  source   = "./modules/diagnostics"

  name                       = "${local.common_name}-${each.key}-diagnostics"
  target_resource_id         = each.value
  log_analytics_workspace_id = module.log_analytics.id
}
