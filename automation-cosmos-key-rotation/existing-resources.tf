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

resource "azurerm_storage_account" "storage" {
	name                     = "<existing-storage-account-name>"
	resource_group_name      = "<existing-storage-resource-group>"
	location                 = "<existing-location>"
	account_tier             = "Standard"
	account_replication_type = "LRS"

	min_tls_version                 = "TLS1_2"
	https_traffic_only_enabled      = true
	shared_access_key_enabled       = true
	public_network_access_enabled   = true

	lifecycle {
		prevent_destroy = true
	}
}

# Import the existing resources before planning:
# terraform import azurerm_cosmosdb_account.cosmos <existing-cosmos-resource-id>
# terraform import azurerm_key_vault.vault <existing-key-vault-resource-id>
# terraform import azurerm_storage_account.storage <existing-storage-account-resource-id>