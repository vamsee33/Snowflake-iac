resource "snowflake_warehouse" "this" {
  name                = var.warehouse.name
  warehouse_size      = var.warehouse.warehouse_size
  warehouse_type      = var.warehouse.warehouse_type
  auto_suspend        = var.warehouse.auto_suspend
  auto_resume         = var.warehouse.auto_resume
  initially_suspended = var.warehouse.initially_suspended
  min_cluster_count   = var.warehouse.min_cluster_count
  max_cluster_count   = var.warehouse.max_cluster_count
  scaling_policy      = var.warehouse.scaling_policy
  resource_monitor    = var.warehouse.resource_monitor
  comment             = var.warehouse.comment
}
