resource "snowflake_role" "this" {
  name    = var.role.name
  comment = var.role.comment
}

resource "snowflake_role_grants" "inheritance" {
  for_each = var.role.parent_role != null ? { "default" = var.role.parent_role } : {}

  role_name = snowflake_role.this.name
  roles     = [each.value]
}
