output "view_name" {
  description = "Fully-qualified Snowflake view name."
  value       = snowflake_view.this.name
}

output "view_id" {
  description = "View identifier returned by the provider."
  value       = snowflake_view.this.id
}
