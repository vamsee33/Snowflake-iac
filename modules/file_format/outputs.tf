output "file_format_name" {
  description = "Fully-qualified Snowflake file format name."
  value       = snowflake_file_format.this.name
}

output "file_format_id" {
  description = "File format identifier returned by the provider."
  value       = snowflake_file_format.this.id
}
