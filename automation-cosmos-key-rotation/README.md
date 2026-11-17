# Cosmos DB and Storage Account Key Rotation

This standalone Terraform root deploys one Azure Automation Account and exactly two runbooks: `regenerate_primary` and `regenerate_secondary`. Each runbook regenerates one side's Cosmos DB read-write key, Cosmos DB read-only key, and Storage Account key, then writes the three values to separate secrets in an existing Azure Key Vault.

The Cosmos DB account, Storage Account, and Key Vault are represented as existing-resource Terraform blocks in `existing-resources.tf` so they can be imported into state. They are not created by this configuration. The Automation Account, runtime environment, packages, runbooks, and role assignments are created here.

## Requirements

- Terraform 1.8 or later and AzureRM provider 4.81.0.
- An existing Cosmos DB account, Storage Account, Key Vault, and Automation resource group in the selected subscription.
- The Key Vault must use Azure RBAC authorization.
- The deployment identity must be able to manage Automation resources and create role assignments on the three existing resources.
- The Automation worker must be able to reach Azure Resource Manager and the Key Vault data endpoint. A private-only vault may require a Hybrid Runbook Worker on a connected network.

The runbooks use a PowerShell 7.4 runtime and pinned packages: `Az.Accounts` 5.5.3, `Az.CosmosDB` 1.22.0, and `Az.KeyVault` 6.6.1. Azure Automation provides the managed Azure CLI required by the scripts; each runbook checks for version 2.64.0 or later.

## Configure Existing Resources

Edit `existing-resources.tf` so each resource block matches the actual Cosmos DB account, Key Vault, and Storage Account configuration. The included values are placeholders. Keep `prevent_destroy = true`, and import all three existing resources before planning:

```powershell
terraform import azurerm_cosmosdb_account.cosmos <existing-cosmos-resource-id>
terraform import azurerm_key_vault.vault <existing-key-vault-resource-id>
terraform import azurerm_storage_account.storage <existing-storage-account-resource-id>
```

Copy `terraform.tfvars.example` to `terraform.tfvars` and set the subscription, Automation resource group, and Automation Account name. Review the six distinct secret names and change them to the names expected by your consumers. Do not place key values or credentials in Terraform files. The imported resources' configuration must match Azure before applying, or Terraform may propose unwanted changes.

## Runbooks and Secrets

| Runbook | Rotated keys | Default Key Vault secrets |
| --- | --- | --- |
| `regenerate_primary` | Cosmos primary read-write, Cosmos primary read-only, Storage key1 | `cosmos-primary-readwrite-key`, `cosmos-primary-readonly-key`, `storage-primary-key` |
| `regenerate_secondary` | Cosmos secondary read-write, Cosmos secondary read-only, Storage key2 | `cosmos-secondary-readwrite-key`, `cosmos-secondary-readonly-key`, `storage-secondary-key` |

Each script authenticates using the Automation Account system-assigned managed identity. It uses Azure CLI to regenerate keys, `Az.CosmosDB` to retrieve the selected Cosmos key family, and `Set-AzKeyVaultSecret` with a `SecureString` to store each value. Storage key listing queries only the relevant key. Key material is not intentionally written to runbook output or Terraform state.

## Permissions

Terraform assigns these built-in roles at resource scope to the Automation Account identity:

| Role | Scope | Purpose and tradeoff |
| --- | --- | --- |
| `DocumentDB Account Contributor` | Cosmos DB account | Supports key regeneration and key listing; also grants broader Cosmos account management. |
| `Storage Account Key Operator Service Role` | Storage Account | Supports listing and regenerating account keys. |
| `Key Vault Secrets Officer` | Key Vault | Writes secrets; also permits reading and deleting secrets in that vault. |

These built-in roles are broader than custom least-privilege roles. Keep their scopes limited to the individual resources and restrict Automation Account administration and runbook-start access. The deployment operator must have permission to create role assignments at each scope. Allow time for role assignment propagation before starting jobs.

## Deploy and Run

Authenticate as the deployment operator, then initialize and review the plan:

```powershell
az login
az account set --subscription <subscription-id>
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and existing-resources.tf, then import the existing resources.
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Start either runbook from the Azure portal or with Azure CLI:

```powershell
az automation runbook start `
  --resource-group <automation-resource-group> `
  --automation-account-name <automation-account-name> `
  --name regenerate_secondary
```

## Rotation Safety

Each runbook performs three rotations sequentially. If a later regeneration or Key Vault write fails, earlier keys may already have changed and their corresponding secrets may already have new versions. There is no automatic rollback. Check each secret's version metadata without retrieving its value, inspect the Automation job status, and restore the affected consumer configuration before retrying. Rotate the secondary side first for typical consumer migrations, validate consumers, and only then schedule primary rotation. A regenerated key is immediately invalid for clients still using its old value.

The runbooks suppress command output and report generic failures to avoid exposing response details. Avoid enabling tracing or printing variables while handling keys. Restrict Terraform state, plan files, runbook editing, and job-start permissions; use a secured remote backend for shared or production deployments.

## Troubleshooting

- Terraform proposes changing or replacing an imported resource: compare `existing-resources.tf` with the actual resource settings and correct it before applying.
- Authorization errors: confirm the deployment operator can assign the roles and that all three Automation identity assignments have propagated.
- Key Vault write or network errors: verify RBAC authorization mode and worker connectivity to the vault endpoint.
- Missing Az cmdlets or Azure CLI version failure: confirm the runbook uses the PowerShell 7.4 runtime and that package imports completed.
- A key changed but its secret did not: treat that key as rotated, resolve the vault issue, regenerate and store it again, and update consumers. Do not assume the previous key remains valid.
