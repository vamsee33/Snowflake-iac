output "user_name" {
  description = "Snowflake user name managed by the user module."
  value       = snowflake_user.this.name
}

output "user_id" {
  description = "User identifier returned by the provider."
  value       = snowflake_user.this.id
}
