terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-platform"
    storage_account_name = "tfstateplatformdev"
    container_name       = "tfstate"
    key                  = "snowflake/dev.terraform.tfstate"
  }
}
