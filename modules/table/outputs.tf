output "table_name" {
  description = "Fully-qualified Snowflake table name."
  value       = snowflake_table.this.name
}

output "table_id" {
  description = "Table identifier returned by the provider."
  value       = snowflake_table.this.id
}
