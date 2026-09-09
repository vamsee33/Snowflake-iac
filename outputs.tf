output "warehouse_names" {
  description = "Names of the Snowflake warehouses managed by Terraform."
  value       = { for k, v in module.warehouse : k => v.warehouse_name }
}

output "schema_names" {
  description = "Names of the Snowflake schemas managed by Terraform."
  value       = { for k, v in module.schema : k => v.schema_name }
}

output "role_names" {
  description = "Names of the Snowflake roles managed by Terraform."
  value       = { for k, v in module.role : k => v.role_name }
}

output "user_names" {
  description = "Names of the Snowflake users managed by Terraform."
  value       = { for k, v in module.user : k => v.user_name }
}

output "database_sources" {
  description = "The Snowflake databases used as data sources in the root module."
  value = {
    sales   = data.snowflake_database.sales.name
    finance = data.snowflake_database.finance.name
    marketing = data.snowflake_database.marketing.name
  }
}
