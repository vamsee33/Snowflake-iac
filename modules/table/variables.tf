variable "table" {
  description = "Snowflake table definition with columns, defaults, identity, and masking options."
  type = object({
    database                   = string
    schema                     = string
    name                       = string
    comment                    = optional(string, null)
    change_tracking            = optional(bool, false)
    cluster_by                 = optional(list(string), [])
    data_retention_time_in_days = optional(number, 1)
    columns = map(object({
      name           = string
      type           = string
      nullable       = optional(bool, true)
      comment        = optional(string, null)
      default        = optional(object({ constant = optional(string, null), expression = optional(string, null), sequence = optional(object({ name = string, schema = optional(string, null), database = optional(string, null), start_num = optional(number, 1), step_num = optional(number, 1) }), null) }), null)
      identity       = optional(object({ start_num = optional(number, 1), step_num = optional(number, 1) }), null)
      masking_policy = optional(string, null)
      collation      = optional(string, null)
    }))
  })

  validation {
    condition     = length(trimspace(var.table.database)) > 0
    error_message = "database must not be empty."
  }

  validation {
    condition     = length(trimspace(var.table.schema)) > 0
    error_message = "schema must not be empty."
  }

  validation {
    condition     = length(trimspace(var.table.name)) > 0
    error_message = "name must not be empty."
  }
}
