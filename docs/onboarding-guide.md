# Onboarding Guide

## 1. Prepare Snowflake

- Create a service user for Terraform automation.
- Generate a key pair for JWT authentication.
- Assign the public key to the Snowflake user.
- Grant enough privileges to manage warehouses, schemas, roles, tables, views, stages, and grants.

## 2. Prepare Azure

- Create or identify the Azure Key Vault.
- Store the Snowflake private key and passphrase as secrets.
- Configure the GitHub repository to use Azure OIDC.
- Set up a federated credential for the branch or environment.

## 3. Configure repository variables

Populate the environment values or use GitHub secrets:

- `ARM_CLIENT_ID`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`
- `SNOWFLAKE_ORGANIZATION_NAME`
- `SNOWFLAKE_ACCOUNT_NAME`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_ROLE`
- `SNOWFLAKE_WAREHOUSE`
- `AZURE_KEY_VAULT_NAME`
- `AZURE_KEY_VAULT_RG`

## 4. Run Terraform locally

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

## 5. Execute in GitHub Actions

Push to the target branch or open a pull request to trigger the workflows.

## 6. Governance review

- Confirm roles align to business ownership boundaries.
- Confirm database ownership stays with DBA teams.
- Review grant assignments and naming conventions before production rollout.
