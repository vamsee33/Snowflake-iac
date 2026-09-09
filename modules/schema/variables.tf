variable "schema" {
  description = "Schema configuration object to create in the target database."
  type = object({
    database                   = string
    schema_name                = string
    comment                    = optional(string, null)
    with_managed_access        = optional(bool, false)
    data_retention_time_in_days = optional(number, 1)
  })

  validation {
    condition     = length(trimspace(var.schema.database)) > 0
    error_message = "database must not be empty."
  }

  validation {
    condition     = length(trimspace(var.schema.schema_name)) > 0
    error_message = "schema_name must not be empty."
  }
}
