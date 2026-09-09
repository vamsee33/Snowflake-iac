resource "snowflake_role_grants" "role_to_role" {
  for_each = { for k, v in var.assignments : k => v if v.principal == "ROLE" && v.parent_role != null }

  role_name = each.value.role_name
  roles     = [each.value.parent_role]
}

resource "snowflake_role_grants" "user_to_role" {
  for_each = { for k, v in var.assignments : k => v if v.principal == "USER" }

  role_name = each.value.role_name
  users     = [each.value.user_name]
}
