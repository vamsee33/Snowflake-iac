resource "azurerm_cosmosdb_account" "cosmos" {
	name                = "<existing-cosmos-account-name>"
	resource_group_name = "<existing-cosmos-resource-group>"
	location            = "<existing-location>"
	offer_type          = "Standard"
	kind                = "GlobalDocumentDB"

	consistency_policy {
		consistency_level = "Session"
	}

	geo_location {
		location          = "<existing-location>"
		failover_priority = 0
	}

	lifecycle {
		prevent_destroy = true
	}
}

resource "azurerm_key_vault" "vault" {
	name                = "<existing-key-vault-name>"
	resource_group_name = "<existing-key-vault-resource-group>"
	location            = "<existing-location>"
	tenant_id           = "<tenant-id>"
	sku_name            = "standard"

	rbac_authorization_enabled = true

	lifecycle {
		prevent_destroy = true
	}
}

# Import the existing resources before planning:
# terraform import azurerm_cosmosdb_account.cosmos <existing-cosmos-resource-id>
# terraform import azurerm_key_vault.vault <existing-key-vault-resource-id>