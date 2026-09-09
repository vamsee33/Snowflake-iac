variable "stage" {
  description = "Snowflake stage configuration for internal, Azure Blob, or AWS S3 stage types."
  type = object({
    name                = string
    database            = string
    schema              = string
    stage_type          = optional(string, "INTERNAL")
    url                 = optional(string, null)
    storage_integration = optional(string, null)
    directory_enabled   = optional(bool, false)
    file_format         = optional(string, null)
    comment             = optional(string, null)
  })

  validation {
    condition     = contains(["INTERNAL", "AZURE", "AZURE_BLOB", "AWS_S3", "S3"], upper(var.stage.stage_type))
    error_message = "stage_type must be one of INTERNAL, AZURE, AZURE_BLOB, AWS_S3, or S3."
  }

  validation {
    condition     = length(trimspace(var.stage.name)) > 0
    error_message = "name must not be empty."
  }
}
