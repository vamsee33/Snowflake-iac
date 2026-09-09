output "warehouse_name" {
  description = "Generated Snowflake warehouse name."
  value       = snowflake_warehouse.this.name
}

output "warehouse_id" {
  description = "Warehouse identifier exposed by the Snowflake provider."
  value       = snowflake_warehouse.this.id
}
