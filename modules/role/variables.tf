variable "role" {
  description = "Role configuration object with optional parent inheritance."
  type = object({
    name        = string
    comment     = optional(string, null)
    parent_role = optional(string, null)
  })

  validation {
    condition     = length(trimspace(var.role.name)) > 0
    error_message = "role.name must not be empty."
  }
}
