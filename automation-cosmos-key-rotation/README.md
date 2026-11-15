# Cosmos DB Key Rotation with Azure Automation

This standalone Terraform root deploys an Azure Automation Account into an existing resource group. Its system-assigned managed identity can regenerate keys for one existing Azure Cosmos DB account and write the rotated values to four named secrets in one existing Azure Key Vault. It does not create, replace, or configure the Cosmos DB account or Key Vault.

## Prerequisites

- Terraform 1.8 or later and Azure CLI for local operator authentication, or an equivalent AzureRM provider authentication method.
- An Azure subscription containing the Automation Account resource group, Cosmos DB account, and Key Vault. This implementation uses one provider subscription for all three.
- An existing Cosmos DB account and an existing Key Vault configured for Azure RBAC authorization.
- An existing resource group for the new Automation Account.
- An operator identity permitted to create Automation Accounts, runtime environments and packages, runbooks, and role assignments at the Cosmos account and Key Vault scopes. The operator also needs read access to the three existing resources.
- Network access from the Automation cloud worker to Azure Resource Manager and the Key Vault data endpoint. A Key Vault reachable only through a private endpoint generally requires a Hybrid Runbook Worker in the connected virtual network.

The runbooks use a dedicated PowerShell 7.4 runtime environment and these pinned PowerShell Gallery packages:

| Package | Version | Purpose |
| --- | --- | --- |
| `Az.Accounts` | `5.5.3` | Managed Identity sign-in |
| `Az.CosmosDB` | `1.22.0` | Cosmos DB key retrieval |
| `Az.KeyVault` | `6.6.1` | Secure secret creation and update |

These versions have compatible `Az.Accounts` dependencies. Azure Automation provides Azure CLI `2.64.0` as a managed default package for PowerShell 7.4 and updates it with its supported runtime. Each runbook checks that `az` is available and at least version 2.64.0 before proceeding. Cosmos key regeneration uses a built-in Azure CLI command, so no CLI extension is required.

## Configuration

From this directory, copy `terraform.tfvars.example` to `terraform.tfvars` and set the subscription, resource group, account, and vault names and full resource IDs. Set secret names to match the conventions expected by your consumers. These ID inputs refer to the existing Cosmos DB account and Key Vault; the configuration does not look them up with data sources or create duplicates. The example contains identifiers only; never put key values, passwords, or credentials in Terraform variables or files.

The four runbooks and default secret names are:

| Runbook | Cosmos key | Default Key Vault secret |
| --- | --- | --- |
| `regenerate_primary_readwrite` | Primary read-write | `cosmos-primary-readwrite-key` |
| `regenerate_secondary_readwrite` | Secondary read-write | `cosmos-secondary-readwrite-key` |
| `regenerate_primary_readonly` | Primary read-only | `cosmos-primary-readonly-key` |
| `regenerate_secondary_readonly` | Secondary read-only | `cosmos-secondary-readonly-key` |

The secret names must be distinct and meet Key Vault naming rules. The Automation Account is created in the location of `automation_resource_group_name`; the other resource groups and resources are looked up, not created.

## Deploy with Terraform

Authenticate as the deployment operator. For a local Azure CLI session:

```powershell
az login
az account set --subscription <subscription-id>
```

Then run from this directory:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with the existing resource identifiers.
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Review the plan before applying. Use a secured remote Terraform backend for team or production use; protect state and plan files, restrict access, enable storage encryption and locking, and do not commit local state, plans, or `terraform.tfvars`. This configuration does not put Cosmos key values into Terraform state.

The deployment creates the Automation Account, its system-assigned managed identity, the PowerShell 7.4 runtime environment, the three pinned runtime packages, two scoped built-in role assignments, and all four runbooks. The RBAC role assignments can take several minutes to propagate before a first job succeeds.

## Managed identity and permissions

The Automation Account uses a system-assigned managed identity. Each runbook authenticates both Azure CLI and Az PowerShell using `az login --identity` and `Connect-AzAccount -Identity`; no service principal secret, certificate, or interactive credential is stored in the account or scripts.

Terraform assigns these built-in roles with `azurerm_role_assignment.role_definition_name`, scoped to the existing resources:

- **DocumentDB Account Contributor**: assigned at the existing Cosmos DB account resource ID. This built-in role includes key regeneration and key listing, which are required because regeneration does not return the new key. The runbook requests only the relevant key family and never emits its contents. The role also allows broader Cosmos DB account management actions.
- **Key Vault Secrets Officer**: assigned at the existing Key Vault resource ID. This built-in role can create and update secrets, but also has read and delete permissions over secrets in the vault.

The two role assignments are scoped only to the existing Cosmos DB account and Key Vault, not the subscription. The deployment operator must be allowed to create role assignments at those resource scopes. The vault must use the Azure RBAC permission model; legacy access-policy mode will not honor the built-in role assignment.

| Assignment | Identity | Scope | Justification |
| --- | --- | --- | --- |
| DocumentDB Account Contributor | Automation Account system identity | Existing Cosmos DB account | Includes the required key regeneration and list-keys operations, but also account management actions. |
| Key Vault Secrets Officer | Automation Account system identity | Existing Key Vault | Allows updating secrets, but also secret read and delete actions. |

## Runbook execution

After Terraform completes and role assignments have propagated, start a runbook from the Azure portal under the Automation Account's **Runbooks**, or use Azure CLI:

```powershell
az automation runbook start `
  --resource-group <automation-resource-group> `
  --automation-account-name <automation-account-name> `
  --name regenerate_secondary_readwrite
```

Use the matching runbook name from the table to rotate a different key. Review the job's status and generic output in the portal or job history. Verbose and progress logging are disabled. The scripts do not emit key values, and errors are replaced with a generic message to avoid leaking response details.

The scripts use Azure CLI for the supported Cosmos DB key regeneration operation and use `Az.CosmosDB` to retrieve the selected key family. They do not use `az keyvault secret set --value`: that command requires passing key material as a command argument. `Set-AzKeyVaultSecret -SecretValue` accepts a `SecureString`, avoids placing the key in a CLI command line, and uses the existing Key Vault RBAC assignment. CLI output and stderr are suppressed, and each command's exit code is checked.

Rotate one key at a time. For a planned client rotation, update and validate consumers with the secondary key before rotating the primary key. A regenerated key is immediately invalid for clients still using the old value; regeneration cannot be rolled back. Read-only keys are also credentials and should be handled with the same care.

## Key Vault storage

Each runbook verifies the managed Azure CLI version, signs in with Managed Identity, and regenerates exactly one key using `az cosmosdb keys regenerate` with output disabled. It then uses `Get-AzCosmosDBAccountKey` to retrieve only the corresponding key family, selects the requested key in memory, converts it to a `SecureString`, and calls `Set-AzKeyVaultSecret`. The secret value is never written to the runbook output, verbose, information, warning, progress, debug, or error streams, Terraform outputs, or Terraform state. The secret update creates a new Key Vault secret version; the result metadata is discarded and the version's value is never printed.

The runbook identity deliberately has no Key Vault get permission. Verify that a secret was updated by checking its version metadata in the portal or with a command that does not request the value:

```powershell
az keyvault secret list-versions `
  --vault-name <key-vault-name> `
  --name cosmos-secondary-readwrite-key `
  --query "[].{id:id,enabled:attributes.enabled}" `
  --output table
```

Do not use `az keyvault secret show` without a metadata-only query, print runbook variables, or enable request/response tracing while handling keys. Consumers should retrieve the current value directly from Key Vault under their own narrowly scoped identity.

## Validation and troubleshooting

- `terraform validate` fails on missing resources: confirm the subscription and all three resource-group names in `terraform.tfvars`, and that the names identify existing resources.
- Role assignment or `AuthorizationFailed` errors: confirm the deployment operator can create role definitions and assignments at the stated scopes; wait for role propagation before retrying a job.
- Key Vault authorization errors: confirm the vault has Azure RBAC authorization enabled and the Automation identity's Key Vault Secrets Officer assignment is present at the vault scope.
- Key Vault network errors: verify the vault firewall/private endpoint permits the Automation execution environment. Use a Hybrid Runbook Worker for private-only network paths; do not broadly enable public access to work around connectivity.
- Azure CLI version check fails: confirm the runbook is associated with `cosmos-key-rotation-pwsh74` using PowerShell 7.4. The runtime supplies the managed CLI; scripts require version 2.64.0 or later and use no extensions.
- `Az` cmdlet not found: check that all three runtime package imports completed successfully and that runbooks are associated with `cosmos-key-rotation-pwsh74` using PowerShell 7.4.
- Runbook reports a generic failure: inspect the job status and Azure Activity Log for authorization, network, or API failures. The runbook intentionally suppresses detailed exceptions; never add key values or raw ARM response bodies to diagnostic output.
- A key rotated but no new secret version exists: the Cosmos key has already changed, but the vault write failed. Restore service by addressing the vault issue and rotating the affected key again, then immediately verify the new secret version and update consumers. The operation has no automatic rollback.

## Security considerations

- Restrict Terraform state, plan files, and deployment identity permissions. Avoid publishing state or plan output to untrusted CI logs.
- The requested built-in roles are broader than custom least-privilege roles: DocumentDB Account Contributor can manage the Cosmos account, and Key Vault Secrets Officer can read and delete all secrets in the vault. Scope them only to the existing resources, restrict Automation Account administration and runbook-start access, and audit key and secret operations. If that access is too broad for policy, custom role definitions with narrower actions are required instead of the built-in-role requirement.
- Protect and monitor the Automation Account, runbook edit permissions, Key Vault, and Cosmos account. Anyone able to change or start runbooks can affect key availability.
- Use Key Vault logging and Azure Activity Logs for auditing. Monitor failed Automation jobs and unexpected secret version creation.
- The Cosmos `listKeys` API returns key material to the runbook process. Azure Automation necessarily holds the selected value transiently in memory before sending it over TLS to Key Vault. This solution does not persist or log it; restrict job and account administration accordingly.
- Key rotation is a service-impacting operation. Coordinate consumer updates, use the secondary key as the normal zero-downtime rotation path, and validate applications before rotating the other key.
- The runbook identity needs the built-in role's key-list permission because the Cosmos key regeneration API does not return a key. This action allows retrieving account keys, so protect Automation Account runbook/job access and audit all starts and edits.
- Pin reviewed provider and package versions and update them through a deliberate change. AzureRM is pinned to `4.81.0`; review provider and package upgrades before applying them to production.