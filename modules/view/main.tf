resource "snowflake_view" "this" {
  database = var.view.database
  schema   = var.view.schema
  name     = var.view.name
  comment  = var.view.comment
  secure   = var.view.secure
  statement = var.view.statement
}
