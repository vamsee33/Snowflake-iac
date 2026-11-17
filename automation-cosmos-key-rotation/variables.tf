variable "subscription_id" {
  description = "Azure subscription containing the Automation Account and target resources."
  type        = string
}

variable "automation_resource_group_name" {
  description = "Existing resource group in which to create the Automation Account."
  type        = string
}

variable "automation_account_name" {
  description = "Globally unique name for the new Azure Automation Account."
  type        = string
}

variable "key_secret_names" {
  description = "Key Vault secret names for the four Cosmos DB keys and two Storage Account keys."
  type = object({
    cosmos_primary_readwrite   = string
    cosmos_secondary_readwrite = string
    cosmos_primary_readonly    = string
    cosmos_secondary_readonly  = string
    storage_primary            = string
    storage_secondary          = string
  })

  default = {
    cosmos_primary_readwrite   = "cosmos-primary-readwrite-key"
    cosmos_secondary_readwrite = "cosmos-secondary-readwrite-key"
    cosmos_primary_readonly    = "cosmos-primary-readonly-key"
    cosmos_secondary_readonly  = "cosmos-secondary-readonly-key"
    storage_primary            = "storage-primary-key"
    storage_secondary          = "storage-secondary-key"
  }

  validation {
    condition = length(distinct(values(var.key_secret_names))) == 6 && alltrue([
      for secret_name in values(var.key_secret_names) : can(regex("^[A-Za-z0-9-]{1,127}$", secret_name))
    ])
    error_message = "All six Key Vault secret names must be distinct, 1-127 characters, and contain only letters, numbers, and hyphens."
  }
}