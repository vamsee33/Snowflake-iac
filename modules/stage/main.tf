resource "snowflake_stage" "this" {
  database = var.stage.database
  schema   = var.stage.schema
  name     = var.stage.name
  comment  = var.stage.comment

  url                 = var.stage.url
  storage_integration = var.stage.storage_integration
  directory_enabled   = var.stage.directory_enabled
  file_format         = var.stage.file_format

  dynamic "aws_s3_stage" {
    for_each = lower(var.stage.stage_type) == "aws_s3" || lower(var.stage.stage_type) == "s3" ? [var.stage] : []
    content {
      url = aws_s3_stage.value.url
    }
  }

  dynamic "azure_stage" {
    for_each = lower(var.stage.stage_type) == "azure" || lower(var.stage.stage_type) == "azure_blob" ? [var.stage] : []
    content {
      url = azure_stage.value.url
      storage_integration = azure_stage.value.storage_integration
    }
  }
}
