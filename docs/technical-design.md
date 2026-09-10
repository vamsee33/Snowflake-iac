# Snowflake IaC Platform Technical Design and Implementation

## 1. Executive Summary

This document defines the target platform design for managing Snowflake infrastructure through Terraform, GitHub Actions, and centralized reusable delivery templates. The architecture standardizes deployment of Snowflake platform objects such as warehouses, databases, schemas, tables, views, roles, users, stages, file formats, and grants while maintaining strong security, environment isolation, and operational governance.

The solution uses a layered design that separates:

- repository-level orchestration and governance,
- Terraform code in a dedicated working directory,
- environment-specific configuration values,
- reusable module contracts,
- centrally managed GitHub workflow templates,
- secure secret retrieval and runtime authentication.

The platform is intentionally designed for enterprise scale. It supports multi-environment promotion, model-driven provisioning, and future expansion into private module registries, policy enforcement, drift detection, and governance automation. The repository is structured to support repeatability, security, and operational clarity across dev, QA, and prod while reducing the risk of configuration drift and uncontrolled change.

---

## 2. Solution Overview

The Snowflake Infrastructure as Code platform follows a modular, environment-aware architecture. The repository is organized to keep infrastructure code separate from application code and to ensure that GitHub Actions executes Terraform from a controlled root path. This design enables standardization, scaling, and future support for multiple Terraform stacks.

Core principles of the design are:

- Infrastructure as Code with version-controlled, reviewable, auditable changes.
- Environment isolation through distinct backend and variable files.
- Reusable Terraform modules to reduce duplication and enforce standards.
- Secure authentication using GitHub OIDC and Snowflake JWT.
- Centralized deployment pipelines with plan-then-apply control.
- Clear ownership boundaries for Snowflake objects and RBAC.

The only structural change in this design is that the Terraform root configuration files move from the repository root into a dedicated `terraform/` folder. The rest of the repository remains the same: documentation, GitHub workflows, and environment files stay in their current locations. This keeps the Terraform execution context explicit while preserving a clean repository boundary and supporting future multi-stack patterns.

---

## 3. Repository Structure

The repository structure is intentionally layered to enable clarity and scaling.

```text
snowflake-infra-repo/
|
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
|
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── backend.tfvars
│   │   │   └── terraform.tfvars
│   │   |
│   │   ├── qa/
│   │   │   ├── backend.tfvars
│   │   │   └── terraform.tfvars
│   │   |
│   │   └── prod/
│   │       ├── backend.tfvars
│   │       └── terraform.tfvars
│   |
│   ├── modules/
│   │   ├── database/
│   │   ├── schema/
│   │   ├── table/
│   │   ├── role/
│   │   ├── user/
│   │   ├── warehouse/
│   │   ├── stage/
│   │   ├── view/
│   │   ├── grants/
│   │   └── file_format/
│   |
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── data.tf
│   ├── locals.tf
│   ├── versions.tf
│   └── README.md
|
├── docs/
│   ├── architecture-diagram.md
│   ├── onboarding-guide.md
│   ├── github-actions-flow.md
│   ├── module-documentation.md
│   ├── troubleshooting-guide.md
│   └── terraform-flow.md
|
├── README.md
├── .gitignore
└── .github/CODEOWNERS
```

### Purpose of each top-level area

#### Repository root
The repository root is used for cross-cutting concerns such as documentation, repository governance, GitHub automation metadata, and reusable standards. It remains the Git-level entry point for source control, while the actual Terraform execution context is intentionally moved under `terraform/`.

#### `terraform/`
This folder represents the Terraform working directory. It contains the actual infrastructure code, environment state configuration, module directories, and declarations that Terraform loads at runtime.

#### `terraform/environments/`
The environment folder holds environment-specific values, security settings, and backend state configuration. Keeping values isolated by environment reduces the risk of cross-environment drift and accidental production modifications.

#### `terraform/modules/`
Modules define standard, reusable patterns for Snowflake objects. Each module encapsulates a resource type and exposes a stable contract through variables and outputs. This creates a consistent developer interface across the platform.

#### `.github/workflows/`
GitHub Actions pipelines orchestrate the lifecycle of Terraform deployments. They provide a standard approval model, environment-specific behavior, and consistent validation gates.

#### `docs/`
The documentation layer captures architecture decisions, operational guidance, onboarding steps, flow diagrams, and support procedures. This is important for governance and for ensuring continuity when the platform scales.

### Why the Terraform root files move to a dedicated folder

The actual change is intentionally narrow: the Terraform root files are moved into a dedicated `terraform/` folder, while the rest of the repository structure remains unchanged.

This provides a few important benefits:

- Better organization: Terraform code is separated from repository-level metadata and documentation.
- Cleaner CI/CD execution: pipelines can run from a known working directory without ambiguity.
- Simpler path resolution: `terraform.tfvars`, `backend.tfvars`, and module paths resolve consistently from one root.
- Future support for multiple stacks: additional Terraform code can be introduced without mixing it with the repository root.

This is not a broad repository redesign. It is a focused change to make the Terraform execution context explicit and consistent.

---

## 4. Environment Design

Environment configuration is a core principle of the platform. Each environment is modeled as a distinct set of inputs and a unique Terraform backend target.

### `backend.tfvars`
`backend.tfvars` files contain remote state configuration. They are used to define:

- the Terraform backend type,
- the remote state storage location,
- state naming and isolation rules,
- environment-scoped locking and access control,
- any required backend-specific metadata.

Example:

```hcl
resource_group_name  = "rg-snowflake-tfstate"
storage_account_name = "sftfstateprod001"
container_name       = "tfstate"
key                  = "snowflake/prod/terraform.tfstate"
```

This file ensures that:

- dev, QA, and prod are isolated,
- the same repository can manage multiple environments safely,
- state corruption or accidental cross-environment mutation is reduced,
- production state remains protected from non-production workflows.

### `terraform.tfvars`
`terraform.tfvars` contains environment-specific runtime values, such as:

- database names,
- schema names,
- warehouse sizing and auto-suspend settings,
- role naming and hierarchy,
- user assignments,
- grant mappings,
- environment override values.

Example:

```hcl
snowflake_role = "SYSADMIN"
snowflake_warehouse = "ETL_WH"

warehouse_map = {
  prod_analytics_wh = {
    name           = "PROD_ANALYTICS_WH"
    warehouse_size = "LARGE"
    auto_suspend  = 600
    auto_resume   = true
  }
}

schema_map = {
  sales = {
    database = "SALES_DB"
    name     = "SALES"
  }
}
```

### Why environment separation is important

Environment separation is critical because Snowflake configuration can affect production workloads, access, and cost. By enforcing distinct backend state and tfvars per environment:

- changes are scoped intentionally,
- approval gates are enforced across boundaries,
- environment drift is easier to identify,
- prod operations can follow a stricter governance model,
- human error is reduced through naming and path consistency.

---

## 5. Module Design Standards

Modules are the core of the Snowflake IaC design. They provide reusable, opinionated implementations for platform primitives, standardizing how Snowflake resources are created and managed.

Each module is expected to follow a common contract:

```text
module-name/
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
```

### File responsibilities

#### `main.tf`
Contains resource definitions and the resource graph for the module. This is where the actual Snowflake resources are created and configured. It also includes relevant validation rules, dependencies, and resource-level governance controls.

#### `variables.tf`
Defines all inputs required for the module. Inputs must be explicit, typed, and documented. This promotes safe use, validation, and reuse across environments.

#### `outputs.tf`
Exports module values to downstream Terraform consumers. These outputs can be used by root modules or by other modules when there is a dependency chain.

#### `README.md`
Describes purpose, input variables, outputs, usage examples, expected dependencies, and any caveats. This is especially important for platform adoption and maintenance.

### Module design principles

Each module should follow these standards:

- use clear and consistent naming,
- avoid hard-coded environment values,
- accept data via variables rather than global assumptions,
- allow `for_each` usage for scale and portfolio alignment,
- produce meaningful outputs for downstream composition,
- support validation and idempotent execution,
- minimize hidden side effects.

### Example modules

#### Database module
Responsibilities:

- create or manage Snowflake databases when owned by the platform,
- expose database identifiers for dependent schemas,
- enforce naming conventions and ownership metadata.

Example call:

```hcl
module "database" {
  source = "./modules/database"

  for_each = var.database_map

  database = each.value
}
```

#### Schema module
Responsibilities:

- create schemas in a known database,
- attach the schema to the correct ownership model,
- support lifecycle management and role-based access.

#### Table module
Responsibilities:

- define table schemas and column types,
- support column-level metadata,
- maintain a repeatable pattern for analytics and operational objects.

Example:

```hcl
module "table" {
  source = "./modules/table"

  for_each = var.table_map

  table = each.value
}
```

#### Role module
Responsibilities:

- create Snowflake roles,
- manage role hierarchy and ownership,
- support downstream grant and user assignment patterns.

#### User module
Responsibilities:

- create or manage service users and human users,
- assign roles and default warehouse configuration,
- keep identity management aligned with least privilege.

#### Warehouse module
Responsibilities:

- create warehouses with size, scaling, auto-suspend, and auto-resume settings,
- support environment-specific compute profiles,
- allow integration with workload ownership and cost control.

Example:

```hcl
module "warehouse" {
  source = "./modules/warehouse"

  for_each = var.warehouse_map

  warehouse = each.value
}
```

### Module governance standard

Modules should not directly embed secrets or environment assumptions. They should expose contract surfaces, while the root module and deployment variables manage environment-specific values. This approach allows modules to remain reusable and portable across teams and systems.

---

## 6. Root Terraform Configuration

The root Terraform configuration is the orchestration layer. It is the place where global definitions, data sources, provider settings, and reusable module invocations are composed.

### `provider.tf`
`provider.tf` contains the Snowflake provider configuration and any required provider-level settings.

Example:

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

This configuration is central to the secure and consistent connection model used by the platform.

### `data.tf`
`data.tf` defines Terraform data sources that read current state from external systems. Examples include:

- Azure Key Vault secrets,
- existing Snowflake objects,
- role information,
- database references,
- current platform metadata.

Example:

```hcl
data "azurerm_key_vault_secret" "snowflake_private_key" {
  name         = var.snowflake_private_key_secret_name
  key_vault_id = data.azurerm_key_vault.snowflake.id
}
```

This pattern ensures that the infrastructure layer can consume current operational information without hard-coding secrets or assumptions.

### `variables.tf`
`variables.tf` contains global variables for the infrastructure layer. This includes authentication, environment metadata, module inputs, and operational settings. These variables are bound by environment-specific `terraform.tfvars` files.

### `outputs.tf`
`outputs.tf` exposes key resource values after deployment. These values are useful for CI validation, downstream automation, and platform visibility.

### `main.tf`
`main.tf` is the composition entry point. It invokes the modules and passes map-driven definitions that describe what should be created in a given environment.

Example:

```hcl
module "warehouse" {
  source = "./modules/warehouse"

  for_each = var.warehouse_map

  warehouse = each.value
}

module "schema" {
  source = "./modules/schema"

  for_each = var.schema_map

  schema = each.value
}
```

The root module resolves platform composition by bringing together standards, environment values, and module contracts into a cohesive configuration.

---

## 7. GitHub Actions Integration

GitHub Actions is the deployment control plane for the Snowflake platform. It is responsible for enforcing repeatable pipeline execution, validating configuration, and protecting production changes through approval patterns.

### Design approach

The repository consumes centralized, organization-wide reusable Terraform workflow templates. This provides standard pipeline behavior without forcing each repository to build custom logic. The platform relies on a standard pattern where templates manage the core flow, while specific repository values such as the working directory, environment, and target tfvars files remain configurable inputs.

### Workflow model

The standard workflow pattern includes:

1. plan stage
2. validation stage
3. approval stage
4. apply stage
5. post-deployment verification

#### Plan stage
The plan stage performs:

- Terraform version setup,
- repository checkout,
- Azure or cloud authentication,
- Terraform init,
- Terraform validate,
- Terraform plan with environment-specific tfvars and backend config.

This stage is designed to show the exact impact of code changes before any mutation occurs.

#### Apply stage
The apply stage is triggered only after approval or branch policy compliance. It performs:

- environment-specific initialization,
- plan consumption or re-plan,
- apply against the target Snowflake environment,
- optional summary export for audit logging.

#### Approval process
The approval process is an operational control that ensures production changes are reviewed by authorized individuals. This is especially important when modifying grants, roles, warehouses, or user assignments that impact security or cost.

#### Environment promotion strategy
The repository supports promotion through environment-specific workflows and strict boundaries:

- dev: standard iterative validation
- QA: integration and regression validation
- prod: gated, approved, controlled deployment

This model aligns with enterprise release governance and supports clear accountability.

### Reusable template consumption

The repository should consume centrally managed Terraform workflow templates with minimal disruption. The key requirement is not to rewrite templates, but to supply the correct inputs so the shared pipeline can discover and execute the Terraform code in the `terraform/` folder.

Example pattern:

```yaml
jobs:
  terraform-plan:
    uses: organization/terraform-workflows/.github/workflows/terraform-plan.yml@v1
    with:
      working_directory: terraform
      environment_name: prod
      tfvars_file: environments/prod/terraform.tfvars
      backend_config: environments/prod/backend.tfvars
```

This design keeps the reusable workflow standard but allows repository-specific configuration to remain portable and safe.

---

## 8. Working Directory Migration Design

This section describes the architectural change from the legacy design to the current design.

### Legacy design

Old pattern:

```text
Repository Root = Terraform Working Directory
```

In the legacy model, Terraform was executed directly from the repository root.

### New design

Current pattern:

```text
Repository Root
└── terraform/
```

The only actual change is that the root Terraform files move under `terraform/` and Terraform execution occurs from that directory.

### Why the change was made

This change was made to make the Terraform execution context explicit and predictable. It does not require a broad repo restructuring; it simply aligns the Terraform working directory with a dedicated folder.

### Benefits achieved

- clearer Terraform execution path,
- consistent `-var-file` and backend lookup behavior,
- easier workflow configuration,
- simpler future expansion to additional stacks.

### Impact on GitHub Actions

The pipelines now execute Terraform from the `terraform` directory. Workflows must specify the working directory and reference environment files relative to that folder.

Example:

```yaml
working-directory: terraform
```

Then commands are executed as:

```bash
terraform init -backend-config=environments/prod/backend.tfvars
terraform plan -var-file=environments/prod/terraform.tfvars
```

### Impact on working directory and path references

All relative paths inside the workflow and scripts must be evaluated relative to the Terraform root, not the repository root.

Examples:

- `modules/...` is now `./modules/...` from the Terraform directory.
- `environments/dev/terraform.tfvars` must be reached as `environments/dev/terraform.tfvars` when invoked from `terraform/`.
- backend config is located under `terraform/environments/...` and not at the repo root.

### Changes required in workflow inputs

Reusable templates must receive values such as:

- `working_directory: terraform`
- `environment_name: dev|qa|prod`
- `tfvars_file: environments/dev/terraform.tfvars`
- `backend_config: environments/dev/backend.tfvars`

This is a small but important contract change. It is usually a non-breaking update to the reusable workflow input model, but it must be enforced consistently.

### Changes required in tfvars lookup

The pipeline must dynamically resolve the environment file path based on the selected environment and the Terraform working directory. Example:

```bash
terraform plan -var-file="environments/${ENVIRONMENT}/terraform.tfvars"
```

The runtime must ensure the file location is correct for both local execution and remote pipeline execution.

### Changes required in backend configuration lookup

The same principle applies to backend configuration. The workflow should resolve the file as:

```bash
terraform init -backend-config="environments/${ENVIRONMENT}/backend.tfvars"
```

This ensures state is managed per environment without confusion or accidental reuse.

### Best practice

The platform should centralize these path calculations in workflow inputs or helper scripts so that the same conventions are used everywhere. This reduces the risk of script drift and ensures consistent execution across environments.

---

## 9. Security Considerations

Security is a foundational design requirement for Snowflake IaC. The platform must protect credentials, limit access, and maintain clear governance boundaries.

### GitHub OIDC authentication

GitHub Actions should authenticate to Azure using GitHub OpenID Connect (OIDC) rather than static cloud secrets when available. This reduces operational risk by removing long-lived credentials from the pipeline.

Benefits:

- no stored Azure client secret in GitHub Actions,
- short-lived, federated trust-based access,
- easier rotation and stronger security posture.

### Secret management

All sensitive material such as Snowflake private keys, passphrases, and cloud credentials must be retrieved from managed secret stores, not checked into the repository. Preferred patterns include:

- Azure Key Vault for Snowflake private key material,
- GitHub environment secrets for non-credential configuration,
- workload identity and OIDC for cloud access.

### Azure Key Vault integration

The repository consumes Snowflake private key material from Azure Key Vault. This keeps cryptographic material outside the source tree and allows centralized secret lifecycle management.

### Snowflake JWT authentication

The Snowflake provider uses JWT-based authentication with a private key pair. This pattern is suitable for automated, non-interactive deployments and supports strong identity separation for the Terraform service principal or service user.

### Least privilege access

The Terraform identity must be scoped to the minimum privilege required to manage the target set of Snowflake objects. This includes:

- role management only where necessary,
- warehouse and schema permissions aligned to the deployment scope,
- restricted database access,
- explicit grant review before production changes.

### State file protection

Terraform state must be protected against unauthorized access and unintended mutation. Recommended controls include:

- remote backend storage,
- encryption at rest,
- access control aligned to the pipeline identity,
- state lock usage for concurrency protection,
- environment-specific state isolation,
- periodic Auditing and drift review.

---

## 10. Operational Guidelines

Operational excellence requires clear and repeatable practices for platform usage.

### Standard operating model

- All infrastructure changes must go through a pull request workflow.
- Changes are planned and reviewed before apply.
- Production changes require explicit approval.
- State and configuration must remain environment-specific.
- Module usage must follow naming and ownership conventions.

### Naming conventions

The platform should enforce a consistent naming pattern for roles, warehouses, users, schemas, and resources. This reduces confusion and enables simpler governance, output parsing, and troubleshooting.

### Validation gates

Before apply, the repository should validate:

- Terraform formatting,
- Terraform syntax validation,
- planning output integrity,
- environment and backend configuration correctness,
- security and compliance checks.

### Role ownership and accountability

Snowflake resources should be mapped to clear operational ownership. This includes:

- data owners,
- platform owners,
- security reviewers,
- release approvers.

This improves governance and ensures that blast radius is understood before changes are approved.

### Change review requirements

A change should be reviewed for:

- security impact,
- cost impact,
- privilege escalation,
- role dependency changes,
- environment blast radius,
- operational readiness.

---

## 11. Future Roadmap

The design is intentionally extensible. The following enhancements are recommended as the platform matures.

1. Private Terraform Module Registry
   - host standard Snowflake modules in a private registry,
   - version modules and control compatibility,
   - improve reuse across teams.

2. Terratest validation
   - add automated infrastructure tests for behavior and lifecycle,
   - validate real deployment patterns before production release.

3. Checkov scanning
   - enforce policy compliance and security checks in CI,
   - detect insecure resource patterns early.

4. Terraform fmt and validate enforcement
   - automate code formatting and syntax validation on every PR,
   - reduce review churn and maintain consistent standards.

5. Cost governance
   - track warehouse sizing and utilization,
   - add budgets, tagging, and cost alerting for compute-heavy workloads.

6. Automated drift detection
   - compare deployed state with source configuration,
   - detect unplanned Snowflake changes and support remediation.

7. Policy as Code
   - enforce guardrails for RBAC, object naming, and lifecycle boundaries,
   - support automated compliance enforcement.

8. Environment promotion workflows
   - support controlled promotion from dev to QA to prod,
   - enforce approval and validation gates between stages.

9. Snowflake RBAC automation
   - formalize ownership-driven role assignment patterns,
   - standardize privilege tiers and policy mapping.

10. Automated documentation generation
   - generate module docs from inputs and outputs,
   - keep architecture and module documentation aligned with repository changes.

These enhancements strengthen the control plane and make the platform more reliable, governable, and scalable.

---

## 12. Conclusion

This Snowflake IaC platform is designed to provide a secure, scalable, repeatable, and enterprise-governed model for managing Snowflake resources. The architecture intentionally separates Terraform execution from the repository root, standardizes module design, isolates environment-specific values, and integrates with reusable GitHub workflow templates.

The result is a platform that is easier to onboard, simpler to maintain, and more resilient in the face of scale. The use of environment-specific `backend.tfvars` and `terraform.tfvars`, secure secret retrieval from Azure Key Vault, and GitHub OIDC-based authentication creates a strong security and operational baseline. 

As the platform evolves, the design will support broader governance, deeper automation, and more advanced reuse patterns without requiring a disruptive redesign. It is an architecture suitable for enterprise adoption and a strong foundation for future Snowflake platform operations.

---

## Appendix: Implementation Notes

### Example working directory execution

```bash
cd terraform
terraform init -backend-config="environments/prod/backend.tfvars"
terraform validate
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### Example root module composition

```hcl
module "warehouse" {
  source = "./modules/warehouse"

  for_each = var.warehouse_map

  warehouse = each.value
}
```

### Example environment contract

```text
terraform/
└── environments/
    ├── dev/
    │   ├── backend.tfvars
    │   └── terraform.tfvars
    ├── qa/
    │   ├── backend.tfvars
    │   └── terraform.tfvars
    └── prod/
        ├── backend.tfvars
        └── terraform.tfvars
```

This structure makes the execution model explicit and ensures that all pipeline operations follow the same repository contract.
