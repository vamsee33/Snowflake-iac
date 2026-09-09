resource "snowflake_table" "this" {
  database = var.table.database
  schema   = var.table.schema
  name     = var.table.name
  comment  = var.table.comment

  change_tracking            = var.table.change_tracking
  cluster_by                 = var.table.cluster_by
  data_retention_time_in_days = var.table.data_retention_time_in_days

  dynamic "column" {
    for_each = var.table.columns
    content {
      name     = column.value.name
      type     = column.value.type
      nullable = column.value.nullable
      comment  = column.value.comment

      default {
        constant  = try(column.value.default.constant, null)
        expression = try(column.value.default.expression, null)

        dynamic "sequence" {
          for_each = try(column.value.default.sequence != null ? [column.value.default.sequence] : [], [])
          content {
            name      = sequence.value.name
            database  = try(sequence.value.database, null)
            schema    = try(sequence.value.schema, null)
            start_num = try(sequence.value.start_num, 1)
            step_num  = try(sequence.value.step_num, 1)
          }
        }
      }

      identity {
        start_num = try(column.value.identity.start_num, 1)
        step_num  = try(column.value.identity.step_num, 1)
      }

      masking_policy = column.value.masking_policy
      collation      = column.value.collation
    }
  }
}
