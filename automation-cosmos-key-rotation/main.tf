locals {
  key_secret_names = {
    cosmos_primary_readwrite   = var.key_secret_names.cosmos_primary_readwrite
    cosmos_secondary_readwrite = var.key_secret_names.cosmos_secondary_readwrite
    cosmos_primary_readonly    = var.key_secret_names.cosmos_primary_readonly
    cosmos_secondary_readonly  = var.key_secret_names.cosmos_secondary_readonly
    storage_primary            = var.key_secret_names.storage_primary
    storage_secondary          = var.key_secret_names.storage_secondary
  }

  runbooks = {
    regenerate_primary = {
    #   key_kind             = "primary"
      cosmos_readwrite_key = local.key_secret_names.cosmos_primary_readwrite
      cosmos_readonly_key  = local.key_secret_names.cosmos_primary_readonly
      storage_key          = local.key_secret_names.storage_primary
      script               = "regenerate-primary.ps1"
      description          = "Regenerates and stores primary Cosmos DB and Storage Account keys."
    }
    regenerate_secondary = {
      key_kind             = "secondary"
      cosmos_readwrite_key = local.key_secret_names.cosmos_secondary_readwrite
      cosmos_readonly_key  = local.key_secret_names.cosmos_secondary_readonly
      storage_key          = local.key_secret_names.storage_secondary
      script               = "regenerate-secondary.ps1"
      description          = "Regenerates and stores secondary Cosmos DB and Storage Account keys."
    }
  }
}

resource "azurerm_automation_account" "rotation" {
  name                = var.automation_account_name
  location            = data.azurerm_resource_group.automation.location
  resource_group_name = data.azurerm_resource_group.automation.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "cosmos_key_rotation" {
  scope                            = azurerm_cosmosdb_account.cosmos.id
  role_definition_name             = "DocumentDB Account Contributor"
  principal_id                     = azurerm_automation_account.rotation.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "key_vault_secret_writer" {
  scope                            = azurerm_key_vault.vault.id
  role_definition_name             = "Key Vault Secrets Officer"
  principal_id                     = azurerm_automation_account.rotation.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_automation_runtime_environment" "rotation" {
  name                    = "cosmos-key-rotation-pwsh74"
  automation_account_id   = azurerm_automation_account.rotation.id
  runtime_language        = "PowerShell"
  runtime_version         = "7.4"
  location                = data.azurerm_resource_group.automation.location
  description             = "Pinned PowerShell 7.4 runtime for Cosmos DB key rotation runbooks."
}

resource "azurerm_automation_runtime_environment_package" "az_accounts" {
  name                              = "Az.Accounts"
  automation_runtime_environment_id = azurerm_automation_runtime_environment.rotation.id
  content_uri                       = "https://www.powershellgallery.com/api/v2/package/Az.Accounts/5.5.3"
  content_version                   = "5.5.3"
}

resource "azurerm_automation_runtime_environment_package" "az_cosmosdb" {
  name                              = "Az.CosmosDB"
  automation_runtime_environment_id = azurerm_automation_runtime_environment.rotation.id
  content_uri                       = "https://www.powershellgallery.com/api/v2/package/Az.CosmosDB/1.22.0"
  content_version                   = "1.22.0"

  depends_on = [azurerm_automation_runtime_environment_package.az_accounts]
}

resource "azurerm_automation_runtime_environment_package" "az_key_vault" {
  name                              = "Az.KeyVault"
  automation_runtime_environment_id = azurerm_automation_runtime_environment.rotation.id
  content_uri                       = "https://www.powershellgallery.com/api/v2/package/Az.KeyVault/6.6.1"
  content_version                   = "6.6.1"

  depends_on = [azurerm_automation_runtime_environment_package.az_accounts]
}

resource "azurerm_automation_runbook" "rotation" {
  for_each = local.runbooks

  name                    = each.key
  location                = data.azurerm_resource_group.automation.location
  resource_group_name     = data.azurerm_resource_group.automation.name
  automation_account_name = azurerm_automation_account.rotation.name
  runbook_type            = "PowerShell"
  runtime_environment_name  = azurerm_automation_runtime_environment.rotation.name
  log_verbose               = false
  log_progress              = false
  description               = each.value.description

  content = templatefile("${path.module}/runbooks/${each.value.script}", {
    cosmos_account_name        = azurerm_cosmosdb_account.cosmos.name
    cosmos_resource_group_name = azurerm_cosmosdb_account.cosmos.resource_group_name
    cosmos_account_id          = azurerm_cosmosdb_account.cosmos.id
    storage_account_name       = azurerm_storage_account.storage.name
    storage_resource_group_name = azurerm_storage_account.storage.resource_group_name
    key_vault_name             = azurerm_key_vault.vault.name
    # key_kind                   = each.value.key_kind
    cosmos_readwrite_secret    = each.value.cosmos_readwrite_key
    cosmos_readonly_secret     = each.value.cosmos_readonly_key
    storage_secret             = each.value.storage_key
  })

  depends_on = [
    azurerm_automation_runtime_environment_package.az_accounts,
    azurerm_automation_runtime_environment_package.az_cosmosdb,
    azurerm_automation_runtime_environment_package.az_key_vault,
    azurerm_role_assignment.cosmos_key_rotation,
    azurerm_role_assignment.storage_key_operator,
    azurerm_role_assignment.key_vault_secret_writer,
  ]
}

resource "azurerm_role_assignment" "storage_key_operator" {
  scope                            = azurerm_storage_account.storage.id
  role_definition_name             = "Storage Account Key Operator Service Role"
  principal_id                     = azurerm_automation_account.rotation.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}