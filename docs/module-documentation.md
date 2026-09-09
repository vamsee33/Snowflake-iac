# Module Documentation

## Warehouse module

Purpose:
- Create and manage Snowflake warehouses.

Key arguments:
- `name`
- `warehouse_size`
- `warehouse_type`
- `auto_suspend`
- `auto_resume`
- `initially_suspended`
- `min_cluster_count`
- `max_cluster_count`
- `scaling_policy`
- `resource_monitor`
- `comment`

Dependencies:
- none beyond provider access and role permissions

## Schema module

Purpose:
- Create a schema in a managed Snowflake database.

Key arguments:
- `database`
- `schema_name`
- `comment`
- `with_managed_access`
- `data_retention_time_in_days`

Dependencies:
- target database must exist or be data-sourced

## Role module

Purpose:
- Create account roles and support role hierarchy.

Key arguments:
- `name`
- `comment`
- `parent_role`

Dependencies:
- parent roles must exist before inheritance is granted

## User module

Purpose:
- Create and manage Snowflake users.

Key arguments:
- `login_name`
- `display_name`
- `email`
- `disabled`
- `default_role`
- `default_warehouse`
- `default_namespace`
- `rsa_public_key`
- `password`

Dependencies:
- target roles and warehouses should exist

## Role assignment module

Purpose:
- Assign users and roles to roles.

Supported patterns:
- User -> Role
- Role -> Role

## Table module

Purpose:
- Create Snowflake tables with typed columns and schema governance.

Key arguments:
- `database`
- `schema`
- `name`
- `comment`
- `change_tracking`
- `cluster_by`
- `data_retention_time_in_days`
- `columns`

Column features:
- name and type
- nullable
- comment
- default constant / expression / sequence
- identity start_num / step_num
- masking_policy
- collation

## View module

Purpose:
- Create secure or non-secure views.

Key arguments:
- `database`
- `schema`
- `name`
- `comment`
- `secure`
- `statement`

## Stage module

Purpose:
- Create internal or external stages.

Supported stage types:
- `INTERNAL`
- `AZURE`
- `AZURE_BLOB`
- `AWS_S3`
- `S3`

Key arguments:
- `url`
- `storage_integration`
- `directory_enabled`
- `file_format`

## File format module

Purpose:
- Create reusable file format definitions.

Supported formats:
- CSV
- JSON
- PARQUET
- AVRO

## Grants module

Purpose:
- Assign privileges to roles according to governance patterns.

Supported grant sets:
- DATABASE USAGE
- SCHEMA USAGE
- SELECT
- INSERT
- UPDATE
- DELETE
- CREATE TABLE
- CREATE VIEW
- OWNERSHIP
- ALL TABLES
- FUTURE TABLES
- ALL VIEWS
- FUTURE VIEWS
