resource "snowflake_database_grant" "database_usage" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "database" && lower(v.privilege) == "usage" }

  database_name = each.value.object_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_schema_grant" "schema_usage" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "schema" && lower(v.privilege) == "usage" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_table_grant" "select" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "table" && lower(v.privilege) == "select" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  table_name    = each.value.object_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_table_grant" "insert" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "table" && lower(v.privilege) == "insert" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  table_name    = each.value.object_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_table_grant" "update" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "table" && lower(v.privilege) == "update" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  table_name    = each.value.object_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_table_grant" "delete" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "table" && lower(v.privilege) == "delete" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  table_name    = each.value.object_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_table_grant" "create_table" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "schema" && lower(v.privilege) == "create table" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_view_grant" "create_view" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "schema" && lower(v.privilege) == "create view" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_table_grant" "ownership" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "table" && lower(v.privilege) == "ownership" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  table_name    = each.value.object_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
  ownership     = true
}

resource "snowflake_view_grant" "ownership_view" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "view" && lower(v.privilege) == "ownership" }

  database_name = each.value.database_name
  schema_name   = each.value.schema_name
  view_name     = each.value.object_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
  ownership     = true
}

resource "snowflake_table_grant" "all_tables" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "database" && lower(v.privilege) == "all tables" }

  database_name = each.value.database_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_table_grant" "future_tables" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "database" && lower(v.privilege) == "future tables" }

  database_name = each.value.database_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_view_grant" "all_views" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "database" && lower(v.privilege) == "all views" }

  database_name = each.value.database_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}

resource "snowflake_view_grant" "future_views" {
  for_each = { for k, v in var.grants : k => v if lower(v.object_type) == "database" && lower(v.privilege) == "future views" }

  database_name = each.value.database_name
  roles         = each.value.roles
  with_grant_option = each.value.with_grant_option
}
