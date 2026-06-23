resource "azurerm_user_assigned_identity" "control_plane" {
  name                = "${var.name}-control-plane"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "control_plane_network" {
  scope                            = var.aks_subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.control_plane.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  dns_prefix                        = var.name
  sku_tier                          = "Standard"
  private_cluster_enabled           = true
  private_dns_zone_id               = "System"
  role_based_access_control_enabled = true
  local_account_disabled            = false
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  image_cleaner_enabled             = true
  image_cleaner_interval_hours      = 48
  azure_policy_enabled              = true
  tags                              = var.tags

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.aks_subnet_id
    auto_scaling_enabled         = true
    node_count                   = var.system_node_min_count
    min_count                    = var.system_node_min_count
    max_count                    = var.system_node_max_count
    max_pods                     = 50
    only_critical_addons_enabled = false
    os_disk_size_gb              = 128
    os_disk_type                 = "Managed"
    type                         = "VirtualMachineScaleSets"
    zones                        = var.zones
    temporary_name_for_rotation  = "systmp"

    upgrade_settings {
      max_surge = "1"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.control_plane.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    network_data_plane  = "azure"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  ingress_application_gateway {
    gateway_id = var.application_gateway_id
  }

  depends_on = [azurerm_role_assignment.control_plane_network]

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                   = "workload"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.this.id
  vm_size                = var.workload_node_vm_size
  vnet_subnet_id         = var.aks_subnet_id
  mode                   = "User"
  auto_scaling_enabled   = true
  node_count             = var.workload_node_min_count
  min_count              = var.workload_node_min_count
  max_count              = var.workload_node_max_count
  max_pods               = 50
  os_disk_size_gb        = 128
  os_disk_type           = "Managed"
  os_type                = "Linux"
  os_sku                 = "Ubuntu"
  node_public_ip_enabled = false
  zones                  = var.zones
  tags                   = var.tags

  upgrade_settings {
    max_surge = "1"
  }

  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "key_vault_secrets" {
  scope                            = var.key_vault_id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "agic_gateway" {
  scope                            = var.application_gateway_id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "agic_subnet" {
  scope                            = var.application_gateway_subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
