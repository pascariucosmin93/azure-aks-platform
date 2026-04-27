output "id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.this.workspace_id
}

output "action_group_id" {
  value = length(azurerm_monitor_action_group.ops) > 0 ? azurerm_monitor_action_group.ops[0].id : null
}
