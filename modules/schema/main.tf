resource "snowflake_schema" "this" {
  database = var.schema.database
  name     = var.schema.schema_name
  comment  = var.schema.comment

  with_managed_access       = var.schema.with_managed_access
  data_retention_time_in_days = var.schema.data_retention_time_in_days
}
