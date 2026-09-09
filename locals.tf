locals {
  environment_name = lower(trimspace(var.environment))

  snowflake_private_key = replace(
    data.azurerm_key_vault_secret.snowflake_private_key.value,
    "\\n",
    "\n"
  )

  snowflake_private_key_passphrase = data.azurerm_key_vault_secret.snowflake_private_key_passphrase.value

  warehouse_map = var.warehouse_map != {} ? var.warehouse_map : {
    "${local.environment_name}_wh" = {
      name           = upper("${local.environment_name}_WH")
      warehouse_size = local.environment_name == "prod" ? "LARGE" : local.environment_name == "qa" ? "MEDIUM" : "SMALL"
      warehouse_type = "STANDARD"
      auto_suspend   = 600
      auto_resume    = true
      initially_suspended = false
      min_cluster_count   = 1
      max_cluster_count   = 1
      scaling_policy      = "STANDARD"
      resource_monitor    = null
      comment             = "${title(local.environment_name)} warehouse"
    }
  }

  schema_map = var.schema_map != {} ? var.schema_map : {
    "${local.environment_name}_schema" = {
      database                   = upper("${local.environment_name}_DB")
      schema_name                = "RAW"
      comment                    = "${title(local.environment_name)} raw schema"
      with_managed_access        = false
      data_retention_time_in_days = 1
    }
  }

  role_map = var.role_map != {} ? var.role_map : {
    "${local.environment_name}_analyst" = {
      name        = upper("${local.environment_name}_ANALYST_ROLE")
      comment     = "${title(local.environment_name)} analytics role"
      parent_role = "SYSADMIN"
    }
  }

  user_map = var.user_map != {} ? var.user_map : {
    "${local.environment_name}_user" = {
      login_name        = upper("${local.environment_name}_USER")
      display_name      = "${title(local.environment_name)} User"
      email             = "${local.environment_name}@example.com"
      disabled          = false
      default_role      = upper("${local.environment_name}_ANALYST_ROLE")
      default_warehouse = upper("${local.environment_name}_WH")
      default_namespace = "${upper(local.environment_name)}_DB.RAW"
      rsa_public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDc..."
    }
  }

  table_map = var.table_map != {} ? var.table_map : {
    "${local.environment_name}_orders" = {
      database                   = upper("${local.environment_name}_DB")
      schema                     = "RAW"
      name                       = upper("${local.environment_name}_ORDERS")
      comment                    = "${title(local.environment_name)} order table"
      change_tracking            = false
      cluster_by                 = ["ORDER_DATE"]
      data_retention_time_in_days = 1
      columns = {
        ORDER_ID = {
          name     = "ORDER_ID"
          type     = "NUMBER(38,0)"
          nullable = false
          comment  = "Order identifier"
        }
        ORDER_DATE = {
          name     = "ORDER_DATE"
          type     = "DATE"
          nullable = false
          comment  = "Order date"
        }
      }
    }
  }

  view_map = var.view_map != {} ? var.view_map : {
    "${local.environment_name}_orders_v" = {
      database = upper("${local.environment_name}_DB")
      schema   = "RAW"
      name     = upper("${local.environment_name}_ORDERS_V")
      comment  = "${title(local.environment_name)} order view"
      secure   = false
      statement = "SELECT * FROM ${upper(local.environment_name)}_DB.RAW.${upper(local.environment_name)}_ORDERS"
    }
  }

  stage_map = var.stage_map != {} ? var.stage_map : {
    "${local.environment_name}_raw_stage" = {
      name                = upper("${local.environment_name}_RAW_STAGE")
      database            = upper("${local.environment_name}_DB")
      schema              = "RAW"
      stage_type          = "INTERNAL"
      url                 = "@${upper(local.environment_name)}_DB.RAW.${upper(local.environment_name)}_RAW_STAGE"
      storage_integration = null
      directory_enabled   = true
      file_format         = "CSV_FF"
      comment             = "${title(local.environment_name)} raw landing stage"
    }
  }

  file_format_map = var.file_format_map != {} ? var.file_format_map : {
    "csv_ff" = {
      name            = "CSV_FF"
      format_type     = "CSV"
      compression     = "AUTO"
      field_delimiter = ","
      skip_header     = 1
      record_delimiter = "\n"
      encoding        = "UTF-8"
      binary_format   = "HEX"
      comment         = "CSV landing file format"
    }
  }

  grant_map = var.grant_map != {} ? var.grant_map : {
    "${local.environment_name}_usage" = {
      privilege        = "USAGE"
      object_type      = "DATABASE"
      object_name      = upper("${local.environment_name}_DB")
      database_name    = upper("${local.environment_name}_DB")
      schema_name      = "RAW"
      roles            = [upper("${local.environment_name}_ANALYST_ROLE")]
      with_grant_option = false
    }
  }
}
