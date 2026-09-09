resource "snowflake_file_format" "this" {
  name        = var.file_format.name
  database    = var.file_format.database
  schema      = var.file_format.schema
  format_type = var.file_format.format_type
  compression = var.file_format.compression
  field_delimiter = var.file_format.field_delimiter
  skip_header = var.file_format.skip_header
  record_delimiter = var.file_format.record_delimiter
  encoding = var.file_format.encoding
  binary_format = var.file_format.binary_format
  comment = var.file_format.comment
}
