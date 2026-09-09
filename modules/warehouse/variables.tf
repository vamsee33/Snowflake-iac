variable "warehouse" {
  description = "Warehouse configuration object to be provisioned in Snowflake."
  type = object({
    name                = string
    warehouse_size      = string
    warehouse_type      = optional(string, "STANDARD")
    auto_suspend        = optional(number, 600)
    auto_resume         = optional(bool, true)
    initially_suspended = optional(bool, false)
    min_cluster_count   = optional(number, 1)
    max_cluster_count   = optional(number, 1)
    scaling_policy      = optional(string, "STANDARD")
    resource_monitor    = optional(string, null)
    comment             = optional(string, null)
  })

  validation {
    condition     = contains(["XSMALL", "SMALL", "MEDIUM", "LARGE", "XLARGE", "XXLARGE", "XXXLARGE"], upper(var.warehouse.warehouse_size))
    error_message = "warehouse_size must be a valid Snowflake warehouse size."
  }

  validation {
    condition     = contains(["STANDARD", "SNOWPARK-OPTIMIZED"], upper(var.warehouse.warehouse_type))
    error_message = "warehouse_type must be STANDARD or SNOWPARK-OPTIMIZED."
  }
}
