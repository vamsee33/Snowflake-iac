terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 1.0.0, < 2.0.0"
    }
  }
}
