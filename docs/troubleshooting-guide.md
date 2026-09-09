# Troubleshooting Guide

## Snowflake JWT authentication failures

Symptoms:
- provider authentication fails
- key parsing error
- invalid JWT or no access to role

Checks:
- validate the private key formatting returned by Azure Key Vault
- confirm the public key is assigned to the correct Snowflake user
- confirm the Snowflake role has the required privileges

## Azure Key Vault access issues

Symptoms:
- `data.azurerm_key_vault_secret` fails
- permission denied to read secrets

Checks:
- grant secret read access to the GitHub OIDC identity or service principal
- verify the key vault resource group and name values are correct

## Grant errors

Symptoms:
- cannot grant privileges to a role
- object does not exist

Checks:
- verify database and schema exist
- confirm privilege names are valid for the object type
- check that ownership or creation privileges are available

## Naming and validation issues

Symptoms:
- invalid warehouse size or stage type
- empty names or invalid email addresses

Checks:
- use valid Snowflake enum values
- ensure each resource object contains required values
- verify variable validation rules are applied
