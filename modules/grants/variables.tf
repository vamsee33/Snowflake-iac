variable "grants" {
  description = "Map of role-based Snowflake grant definitions."
  type = map(object({
    privilege         = string
    object_type      = string
    object_name      = string
    database_name    = optional(string, null)
    schema_name      = optional(string, null)
    roles            = list(string)
    with_grant_option = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for v in var.grants : length(v.roles) > 0
    ])
    error_message = "Each grant must have at least one role."
  }
}
