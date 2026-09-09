output "stage_name" {
  description = "Fully-qualified Snowflake stage name."
  value       = snowflake_stage.this.name
}

output "stage_id" {
  description = "Stage identifier returned by the provider."
  value       = snowflake_stage.this.id
}
