provider "azurerm" {
  features {}
}

provider "snowflake" {
  organization_name      = var.organization_name
  account_name           = var.account_name
  user                   = var.snowflake_user
  role                   = var.snowflake_role
  warehouse              = var.snowflake_warehouse
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = local.snowflake_private_key
  private_key_passphrase = local.snowflake_private_key_passphrase
}
