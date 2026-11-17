output "automation_account_name" {
  description = "Name of the created Automation Account."
  value       = azurerm_automation_account.rotation.name
}

output "automation_account_id" {
  description = "Resource ID of the created Automation Account."
  value       = azurerm_automation_account.rotation.id
}

output "runtime_environment_name" {
  description = "Name of the PowerShell 7.4 Automation Runtime Environment."
  value       = azurerm_automation_runtime_environment.rotation.name
}

output "managed_identity_principal_id" {
  description = "Principal ID of the Automation Account system-assigned managed identity."
  value       = azurerm_automation_account.rotation.identity[0].principal_id
}

output "runbook_names" {
  description = "Names of the primary and secondary Cosmos DB and Storage Account key rotation runbooks."
  value       = { for name, runbook in azurerm_automation_runbook.rotation : name => runbook.name }
}

output "key_vault_secret_names" {
  description = "The six Key Vault secret names written by the primary and secondary runbooks."
  value       = local.key_secret_names
}