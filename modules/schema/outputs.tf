output "schema_name" {
  description = "Schema fully-qualified name in the target database."
  value       = snowflake_schema.this.name
}

output "schema_id" {
  description = "Schema identifier returned by the provider."
  value       = snowflake_schema.this.id
}
