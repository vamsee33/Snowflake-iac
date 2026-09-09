variable "user" {
  description = "Snowflake user configuration object."
  type = object({
    login_name        = string
    display_name      = string
    email             = string
    disabled          = optional(bool, false)
    default_role      = string
    default_warehouse = optional(string, null)
    default_namespace = optional(string, null)
    rsa_public_key    = string
    password          = optional(string, null)
  })

  validation {
    condition     = length(trimspace(var.user.login_name)) > 0
    error_message = "login_name must not be empty."
  }

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.user.email))
    error_message = "email must be a valid email address."
  }
}
