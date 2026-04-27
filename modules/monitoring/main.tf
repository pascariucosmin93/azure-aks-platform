resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# Container Insights — enables rich AKS metrics and container-level logs
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

resource "azurerm_monitor_action_group" "ops" {
  count               = var.alert_email != null ? 1 : 0
  name                = "${var.name}-ops-ag"
  resource_group_name = var.resource_group_name
  short_name          = "ops"

  email_receiver {
    name          = "ops-team"
    email_address = var.alert_email
  }

  tags = var.tags
}
