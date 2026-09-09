variable "environment" {
  description = "Deployment environment name. Used for naming and tagging conventions in the repository."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "The environment must be one of: dev, qa, prod."
  }
}

variable "organization_name" {
  description = "Snowflake organization name used by the Snowflake provider."
  type        = string
}

variable "account_name" {
  description = "Snowflake account name used by the Snowflake provider."
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user that authenticates with the JWT key pair."
  type        = string
}

variable "snowflake_role" {
  description = "Default Snowflake role for Terraform operations."
  type        = string
}

variable "snowflake_warehouse" {
  description = "Default Snowflake warehouse for Terraform operations."
  type        = string
}

variable "azure_key_vault_name" {
  description = "Name of the Azure Key Vault containing the Snowflake private key and passphrase."
  type        = string
}

variable "azure_key_vault_resource_group_name" {
  description = "Resource group containing the Azure Key Vault used for Snowflake runtime secrets."
  type        = string
}

variable "snowflake_private_key_secret_name" {
  description = "Azure Key Vault secret name for the Snowflake private key in PEM format."
  type        = string
  default     = "snowflake-private-key"
}

variable "snowflake_private_key_passphrase_secret_name" {
  description = "Azure Key Vault secret name for the Snowflake private key passphrase."
  type        = string
  default     = "snowflake-private-key-passphrase"
}

variable "arm_use_oidc" {
  description = "Use GitHub OIDC authentication to Azure instead of a service principal secret."
  type        = bool
  default     = false
}

variable "arm_client_id" {
  description = "Azure AD application client ID used when OIDC is not enabled."
  type        = string
  default     = null
}

variable "arm_client_secret" {
  description = "Azure AD application client secret used when OIDC is not enabled."
  type        = string
  default     = null
  sensitive   = true
}

variable "arm_tenant_id" {
  description = "Azure tenant ID for authentication."
  type        = string
  default     = null
}

variable "arm_subscription_id" {
  description = "Azure subscription ID for authentication."
  type        = string
  default     = null
}

variable "warehouse_map" {
  description = "Map of Snowflake warehouses to create in the target account."
  type = map(object({
    name                 = string
    warehouse_size       = string
    warehouse_type       = optional(string, "STANDARD")
    auto_suspend         = optional(number, 600)
    auto_resume          = optional(bool, true)
    initially_suspended  = optional(bool, false)
    min_cluster_count    = optional(number, 1)
    max_cluster_count    = optional(number, 1)
    scaling_policy       = optional(string, "STANDARD")
    resource_monitor     = optional(string, null)
    comment              = optional(string, null)
  }))
  default = {}
}

variable "schema_map" {
  description = "Map of Snowflake schemas to create for each database."
  type = map(object({
    database                  = string
    schema_name               = string
    comment                   = optional(string, null)
    with_managed_access       = optional(bool, false)
    data_retention_time_in_days = optional(number, 1)
  }))
  default = {}
}

variable "role_map" {
  description = "Map of Snowflake roles to create. Supports parent-child hierarchy."
  type = map(object({
    name            = string
    comment         = optional(string, null)
    parent_role     = optional(string, null)
  }))
  default = {}
}

variable "user_map" {
  description = "Map of Snowflake users to create. Uses public key authentication and optional password fallback."
  type = map(object({
    login_name       = string
    display_name     = string
    email            = string
    disabled         = optional(bool, false)
    default_role     = string
    default_warehouse = optional(string, null)
    default_namespace = optional(string, null)
    rsa_public_key   = string
    password         = optional(string, null)
  }))
  default = {}
}

variable "table_map" {
  description = "Map of Snowflake tables to create for the target schemas."
  type = map(object({
    database                   = string
    schema                     = string
    name                       = string
    comment                    = optional(string, null)
    change_tracking            = optional(bool, false)
    cluster_by                 = optional(list(string), [])
    data_retention_time_in_days = optional(number, 1)
    columns = map(object({
      name           = string
      type           = string
      nullable       = optional(bool, true)
      comment        = optional(string, null)
      default        = optional(object({ constant = optional(string, null), expression = optional(string, null), sequence = optional(object({ name = string, schema = optional(string,null), database = optional(string,null), start_num = optional(number,1), step_num = optional(number,1) }), null) }), null)
      identity       = optional(object({ start_num = optional(number, 1), step_num = optional(number, 1) }), null)
      masking_policy = optional(string, null)
      collation      = optional(string, null)
    }))
  }))
  default = {}
}

variable "view_map" {
  description = "Map of Snowflake views to create for the target schemas."
  type = map(object({
    database = string
    schema   = string
    name     = string
    comment  = optional(string, null)
    secure   = optional(bool, false)
    statement = string
  }))
  default = {}
}

variable "stage_map" {
  description = "Map of Snowflake stages to create. Supports internal and external stages."
  type = map(object({
    name                = string
    database            = string
    schema              = string
    stage_type          = optional(string, "INTERNAL")
    url                 = optional(string, null)
    storage_integration = optional(string, null)
    directory_enabled   = optional(bool, false)
    file_format         = optional(string, null)
    comment             = optional(string, null)
  }))
  default = {}
}

variable "file_format_map" {
  description = "Map of Snowflake file format definitions."
  type = map(object({
    name               = string
    format_type        = string
    compression        = optional(string, "AUTO")
    field_delimiter    = optional(string, ",")
    skip_header        = optional(number, 0)
    record_delimiter   = optional(string, "\n")
    encoding           = optional(string, "UTF-8")
    binary_format      = optional(string, "HEX")
    comment            = optional(string, null)
  }))
  default = {}
}

variable "grant_map" {
  description = "Map of Snowflake grants to assign by role."
  type = map(object({
    privilege      = string
    object_type   = string
    object_name   = string
    database_name = optional(string, null)
    schema_name   = optional(string, null)
    roles         = list(string)
    with_grant_option = optional(bool, false)
  }))
  default = {}
}
