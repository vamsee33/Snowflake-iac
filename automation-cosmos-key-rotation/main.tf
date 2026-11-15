locals {
  key_secret_names = {
    primary_readwrite   = var.key_secret_names.primary_readwrite
    secondary_readwrite = var.key_secret_names.secondary_readwrite
    primary_readonly    = var.key_secret_names.primary_readonly
    secondary_readonly  = var.key_secret_names.secondary_readonly
  }

  runbooks = {
    regenerate_primary_readwrite = {
      key_kind    = "primary"
      secret_name = local.key_secret_names.primary_readwrite
      script      = "regenerate-primary-readwrite.ps1"
      description = "Regenerates and stores the Cosmos DB primary read-write key."
    }
    regenerate_secondary_readwrite = {
      key_kind    = "secondary"
      secret_name = local.key_secret_names.secondary_readwrite
      script      = "regenerate-secondary-readwrite.ps1"
      description = "Regenerates and stores the Cosmos DB secondary read-write key."
    }
    regenerate_primary_readonly = {
      key_kind    = "primaryReadonly"
      secret_name = local.key_secret_names.primary_readonly
      script      = "regenerate-primary-readonly.ps1"
      description = "Regenerates and stores the Cosmos DB primary read-only key."
    }
    regenerate_secondary_readonly = {
      key_kind    = "secondaryReadonly"
      secret_name = local.key_secret_names.secondary_readonly
      script      = "regenerate-secondary-readonly.ps1"
      description = "Regenerates and stores the Cosmos DB secondary read-only key."
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
    key_vault_name             = azurerm_key_vault.vault.name
    secret_name                = each.value.secret_name
    key_kind                   = each.value.key_kind
  })

  depends_on = [
    azurerm_automation_runtime_environment_package.az_accounts,
    azurerm_automation_runtime_environment_package.az_cosmosdb,
    azurerm_automation_runtime_environment_package.az_key_vault,
    azurerm_role_assignment.cosmos_key_rotation,
    azurerm_role_assignment.key_vault_secret_writer,
  ]
}