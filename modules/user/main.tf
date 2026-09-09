resource "snowflake_user" "this" {
  name              = var.user.login_name
  login_name        = var.user.login_name
  display_name      = var.user.display_name
  email             = var.user.email
  disabled          = var.user.disabled
  default_role      = var.user.default_role
  default_warehouse = var.user.default_warehouse
  default_namespace = var.user.default_namespace
  rsa_public_key    = var.user.rsa_public_key
  password          = var.user.password
}
