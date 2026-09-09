output "role_name" {
  description = "Snowflake role name managed by the role module."
  value       = snowflake_role.this.name
}

output "role_id" {
  description = "Role identifier returned by the provider."
  value       = snowflake_role.this.id
}
