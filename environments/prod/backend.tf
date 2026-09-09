terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-platform"
    storage_account_name = "tfstateplatformprod"
    container_name       = "tfstate"
    key                  = "snowflake/prod.terraform.tfstate"
  }
}
