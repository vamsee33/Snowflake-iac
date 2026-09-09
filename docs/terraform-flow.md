# Terraform Flow

1. Read Azure Key Vault secrets.
2. Normalize the Snowflake private key value for newline formatting.
3. Authenticate to Snowflake with `SNOWFLAKE_JWT`.
4. Read required Snowflake database data sources.
5. Create or update warehouses, roles, users, schemas, tables, and views.
6. Apply grants and stage/file format definitions.
7. Emit outputs for validation and downstream automation.

## Main execution order

```mermaid
sequenceDiagram
    participant A as Terraform
    participant B as Azure Key Vault
    participant C as Snowflake

    A->>B: Read key and passphrase
    B-->>A: Secret values
    A->>A: Normalize PEM private key
    A->>C: Authenticate with JWT
    A->>C: Read database data sources
    A->>C: Create warehouses
    A->>C: Create schemas
    A->>C: Create roles and users
    A->>C: Create tables and views
    A->>C: Create stages and file formats
    A->>C: Apply grants
    A-->>A: Output summary
```
