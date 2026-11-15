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
  description = "Key Vault secret names that will receive the four rotated Cosmos DB keys."
  type = object({
    primary_readwrite   = string
    secondary_readwrite = string
    primary_readonly    = string
    secondary_readonly  = string
  })

  default = {
    primary_readwrite   = "cosmos-primary-readwrite-key"
    secondary_readwrite = "cosmos-secondary-readwrite-key"
    primary_readonly    = "cosmos-primary-readonly-key"
    secondary_readonly  = "cosmos-secondary-readonly-key"
  }

  validation {
    condition = length(distinct(values(var.key_secret_names))) == 4 && alltrue([
      for secret_name in values(var.key_secret_names) : can(regex("^[A-Za-z0-9-]{1,127}$", secret_name))
    ])
    error_message = "Key Vault secret names must be distinct, 1-127 characters, and contain only letters, numbers, and hyphens."
  }
}