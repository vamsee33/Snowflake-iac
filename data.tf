data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "snowflake" {
  name                = var.azure_key_vault_name
  resource_group_name = var.azure_key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "snowflake_private_key" {
  name         = var.snowflake_private_key_secret_name
  key_vault_id = data.azurerm_key_vault.snowflake.id
}

data "azurerm_key_vault_secret" "snowflake_private_key_passphrase" {
  name         = var.snowflake_private_key_passphrase_secret_name
  key_vault_id = data.azurerm_key_vault.snowflake.id
}

data "snowflake_database" "sales" {
  name = "SALES_DB"
}

data "snowflake_database" "finance" {
  name = "FINANCE_DB"
}

data "snowflake_database" "marketing" {
  name = "MARKETING_DB"
}
