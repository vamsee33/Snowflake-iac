terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-platform"
    storage_account_name = "tfstateplatformqa"
    container_name       = "tfstate"
    key                  = "snowflake/qa.terraform.tfstate"
  }
}
