variable "file_format" {
  description = "Snowflake file format configuration used by stages and data loads."
  type = object({
    name             = string
    database         = string
    schema           = string
    format_type      = string
    compression      = optional(string, "AUTO")
    field_delimiter  = optional(string, ",")
    skip_header      = optional(number, 0)
    record_delimiter = optional(string, "\n")
    encoding         = optional(string, "UTF-8")
    binary_format    = optional(string, "HEX")
    comment          = optional(string, null)
  })

  validation {
    condition     = contains(["CSV", "JSON", "PARQUET", "AVRO"], upper(var.file_format.format_type))
    error_message = "format_type must be one of CSV, JSON, PARQUET, or AVRO."
  }

  validation {
    condition     = length(trimspace(var.file_format.name)) > 0
    error_message = "name must not be empty."
  }
}
