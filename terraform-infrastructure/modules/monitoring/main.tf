resource "azurerm_monitor_action_group" "this" {
  name                = "${var.name_prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = substr(replace(var.name_prefix, "-", ""), 0, 12)
  tags                = var.tags

  email_receiver {
    name                    = "platform-operations"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_activity_log_alert" "resource_health" {
  name                = "${var.name_prefix}-resource-health"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = [var.resource_group_id]
  description         = "Notify when an Azure resource in the platform resource group becomes unhealthy."
  tags                = var.tags

  criteria {
    category = "ResourceHealth"
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

locals {
  base_metric_alerts = {
    aks_node_cpu = {
      scope       = var.aks_id
      namespace   = "Microsoft.ContainerService/managedClusters"
      metric      = "node_cpu_usage_percentage"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
      severity    = 2
      description = "AKS average node CPU usage is above 80 percent."
    }
    postgresql_cpu = {
      scope       = var.postgresql_id
      namespace   = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric      = "cpu_percent"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
      severity    = 2
      description = "PostgreSQL CPU usage is above 80 percent."
    }
    postgresql_storage = {
      scope       = var.postgresql_id
      namespace   = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric      = "storage_percent"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
      severity    = 1
      description = "PostgreSQL storage usage is above 80 percent."
    }
    appgw_unhealthy_hosts = {
      scope       = var.application_gateway_id
      namespace   = "Microsoft.Network/applicationGateways"
      metric      = "UnhealthyHostCount"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 0
      severity    = 1
      description = "Application Gateway has unhealthy backend hosts."
    }
    servicebus_deadlettered = {
      scope       = var.service_bus_id
      namespace   = "Microsoft.ServiceBus/namespaces"
      metric      = "DeadletteredMessages"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 0
      severity    = 2
      description = "Service Bus has dead-lettered messages."
    }
  }

  vm_metric_alerts = var.vm_alert_enabled ? {
    vm_cpu = {
      scope       = var.vm_id
      namespace   = "Microsoft.Compute/virtualMachines"
      metric      = "Percentage CPU"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
      severity    = 2
      description = "Jumpbox VM CPU usage is above 80 percent."
    }
  } : {}

  metric_alerts = merge(local.base_metric_alerts, local.vm_metric_alerts)
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each            = local.metric_alerts
  name                = "${var.name_prefix}-${replace(each.key, "_", "-")}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.scope]
  description         = each.value.description
  severity            = each.value.severity
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = each.value.namespace
    metric_name      = each.value.metric
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}
