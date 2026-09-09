variable "assignments" {
  description = "Role assignment map defining user-to-role and role-to-role inheritance relationships."
  type = map(object({
    role_name   = string
    parent_role = optional(string, null)
    principal   = optional(string, "ROLE")
    user_name   = optional(string, null)
    grant_name  = optional(string, null)
  }))

  validation {
    condition = alltrue([
      for v in var.assignments : contains(["ROLE", "USER"], upper(coalesce(v.principal, "ROLE")))
    ])
    error_message = "principal must be either ROLE or USER."
  }
}
