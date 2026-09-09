variable "view" {
  description = "Snowflake view definition with secure and statement-based creation."
  type = object({
    database = string
    schema   = string
    name     = string
    comment  = optional(string, null)
    secure   = optional(bool, false)
    statement = string
  })

  validation {
    condition     = length(trimspace(var.view.database)) > 0
    error_message = "database must not be empty."
  }

  validation {
    condition     = length(trimspace(var.view.schema)) > 0
    error_message = "schema must not be empty."
  }

  validation {
    condition     = length(trimspace(var.view.name)) > 0
    error_message = "name must not be empty."
  }

  validation {
    condition     = length(trimspace(var.view.statement)) > 0
    error_message = "statement must not be empty."
  }
}
