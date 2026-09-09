module "warehouse" {
  source = "./modules/warehouse"

  for_each = var.warehouse_map

  warehouse = each.value
}

module "schema" {
  source = "./modules/schema"

  for_each = var.schema_map

  schema = each.value
}

module "role" {
  source = "./modules/role"

  for_each = var.role_map

  role = each.value
}

module "user" {
  source = "./modules/user"

  for_each = var.user_map

  user = each.value
}

module "role_assignment" {
  source = "./modules/role_assignment"

  assignments = {
    for k, v in var.role_map : k => {
      role_name     = v.name
      parent_role   = v.parent_role
      principal     = "ROLE"
      grant_name    = v.name
    }
  }
}

module "table" {
  source = "./modules/table"

  for_each = var.table_map

  table = each.value
}

module "view" {
  source = "./modules/view"

  for_each = var.view_map

  view = each.value
}

module "stage" {
  source = "./modules/stage"

  for_each = var.stage_map

  stage = each.value
}

module "file_format" {
  source = "./modules/file_format"

  for_each = var.file_format_map

  file_format = each.value
}

module "grants" {
  source = "./modules/grants"

  grants = var.grant_map
}
