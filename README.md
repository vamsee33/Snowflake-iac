# Snowflake Infrastructure as Code

This repository provides an enterprise-grade Terraform implementation for Snowflake using Azure Key Vault-backed JWT key authentication, GitHub OIDC for Azure login, and reusable, map-driven modules for Snowflake platform objects.

## Architecture overview

- Terraform authenticates to Snowflake with `SNOWFLAKE_JWT`.
- The private key and passphrase are retrieved from Azure Key Vault with `data "azurerm_key_vault_secret"`.
- Azure authentication prefers GitHub OIDC and includes `ARM_CLIENT_ID` / `ARM_CLIENT_SECRET` fallback.
- Database ownership is delegated to DBA teams; this repository consumes databases via Snowflake data sources.
- Modules are reusable, `for_each`-driven, and built for enterprise governance.

## Repository structure

```text
snowflake-iac/
├── .github/
│   └── workflows/
│       ├── pull-request.yml
│       └── deploy.yml
├── modules/
│   ├── warehouse/
│   ├── schema/
│   ├── role/
│   ├── user/
│   ├── role_assignment/
│   ├── table/
│   ├── view/
│   ├── stage/
│   ├── file_format/
│   └── grants/
├── environments/
│   ├── dev/
│   ├── qa/
│   └── prod/
├── providers.tf
├── versions.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── main.tf
├── data.tf
├── README.md
├── docs/
│   ├── architecture-diagram.md
│   ├── module-documentation.md
│   ├── terraform-flow.md
│   ├── github-actions-flow.md
│   ├── snowflake-object-relationship.md
│   ├── troubleshooting-guide.md
│   └── onboarding-guide.md
└── .gitignore
```

## Authentication model

### Snowflake JWT authentication

```hcl
provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.snowflake_user
  role              = var.snowflake_role
  warehouse         = var.snowflake_warehouse
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = local.snowflake_private_key
  private_key_passphrase = local.snowflake_private_key_passphrase
}
```

### Azure authentication

```hcl
provider "azurerm" {
  features {}
  use_oidc        = var.arm_use_oidc
  client_id       = var.arm_use_oidc ? null : var.arm_client_id
  client_secret   = var.arm_use_oidc ? null : var.arm_client_secret
  tenant_id       = var.arm_tenant_id
  subscription_id = var.arm_subscription_id
}
```

### Secret retrieval from Azure Key Vault

```hcl
data "azurerm_key_vault_secret" "snowflake_private_key" {
  name         = var.snowflake_private_key_secret_name
  key_vault_id = data.azurerm_key_vault.snowflake.id
}

locals {
  snowflake_private_key = replace(
    data.azurerm_key_vault_secret.snowflake_private_key.value,
    "\\n",
    "\n"
  )

  snowflake_private_key_passphrase = data.azurerm_key_vault_secret.snowflake_private_key_passphrase.value
}
```

## Database ownership model

This repository does not create databases. Snowflake databases are treated as owned by DBA teams and are imported via data sources. Example:

```hcl
data "snowflake_database" "sales" {
  name = "SALES_DB"
}
```

## Root module examples

### Data source

```hcl
data "snowflake_database" "finance" {
  name = "FINANCE_DB"
}
```

### Warehouse

```hcl
module "warehouse" {
  source = "./modules/warehouse"

  for_each = var.warehouse_map

  warehouse = each.value
}
```

### Schema

```hcl
module "schema" {
  source = "./modules/schema"

  for_each = var.schema_map

  schema = each.value
}
```

### Role

```hcl
module "role" {
  source = "./modules/role"

  for_each = var.role_map

  role = each.value
}
```

### User

```hcl
module "user" {
  source = "./modules/user"

  for_each = var.user_map

  user = each.value
}
```

### Role assignment

```hcl
module "role_assignment" {
  source = "./modules/role_assignment"

  assignments = {
    "prod_analyst" = {
      role_name   = "ANALYST_ROLE"
      parent_role = "SYSADMIN"
      principal   = "ROLE"
    }
  }
}
```

### Table

```hcl
module "table" {
  source = "./modules/table"

  for_each = var.table_map

  table = each.value
}
```

### View

```hcl
module "view" {
  source = "./modules/view"

  for_each = var.view_map

  view = each.value
}
```

### Stage

```hcl
module "stage" {
  source = "./modules/stage"

  for_each = var.stage_map

  stage = each.value
}
```

### File format

```hcl
module "file_format" {
  source = "./modules/file_format"

  for_each = var.file_format_map

  file_format = each.value
}
```

### Grants

```hcl
module "grants" {
  source = "./modules/grants"

  grants = var.grant_map
}
```

## Module standards

Every module under `modules/` contains:

- `main.tf`
- `variables.tf`
- `outputs.tf`

These modules are designed to be:

- reusable
- map-driven
- `for_each`-driven
- easy to extend
- validation-aware
- output-rich

## Documentation set

See the documents in the `docs/` folder for detailed explanations:

- [docs/architecture-diagram.md](docs/architecture-diagram.md)
- [docs/technical-design.md](docs/technical-design.md)
- [docs/module-documentation.md](docs/module-documentation.md)
- [docs/terraform-flow.md](docs/terraform-flow.md)
- [docs/github-actions-flow.md](docs/github-actions-flow.md)
- [docs/snowflake-object-relationship.md](docs/snowflake-object-relationship.md)
- [docs/troubleshooting-guide.md](docs/troubleshooting-guide.md)
- [docs/onboarding-guide.md](docs/onboarding-guide.md)

## Workflow summary

- `pull-request.yml`: format, init, validate, and plan
- `deploy.yml`: OIDC login, init, validate, plan, and apply

These workflows use Azure federated credentials and avoid long-lived secrets when OIDC is available.

## Notes

- This repository is intentionally focused on platform governance rather than database creation.
- Snowflake objects are modeled as explicit resources where the organization owns the object lifecycle.
- Secrets are never committed to version control.

## Prerequisites

Before running Terraform, configure:

1. A Snowflake service/user with a JWT public key assigned.
2. Private key and passphrase stored in Azure Key Vault.
3. GitHub OIDC federated credential in Azure for repository access.
4. Required environment variables or `tfvars` values for the target environment.

## Validation status

Terraform was not installed in this execution environment, so `terraform fmt`, `terraform init`, and `terraform validate` could not be executed here. The repository files are generated and ready to be executed in an environment with Terraform installed.
