resource "random_id" "this" {
  count       = var.enable_module ? 1 : 0
  byte_length = 3 // ${random_id.this[count.index].hex}
}

resource "random_string" "this" {
  count   = var.enable_module ? 1 : 0  
  length  = 3 // ${random_string.this[count.index].result}
  numeric = true
  lower   = true
  special = false
  upper   = false
}

##################################
### RESOURCE MODULE: USER POOL  
##################################

## Create cognito pool id
resource "aws_cognito_user_pool" "pool" {
  count  = var.enable_module ? 1 : 0
  name   = "${var.environment}-${var.cognito_pool_name}-${random_id.this[count.index].hex}"

  ## Attributes : How do you want your end users to sign in? email for sign-in (optional) and set auto-verified attributes
  username_attributes      = var.sign_in_attribute != "" ? var.sign_in_attribute : null
  auto_verified_attributes = var.auto_verified_attributes != "" ? var.auto_verified_attributes : null
  deletion_protection      = var.deletion_protection != "" ? var.deletion_protection : null

  username_configuration {
    case_sensitive = var.case_sensitive_username
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = var.sign_in_attribute == "email" ? true : false

    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  ## Custom Attributes : Dynamically add custom schemas
  dynamic "schema" {
    for_each = var.custom_schemas
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
      required                 = schema.value.required

      string_attribute_constraints {
        min_length = schema.value.min_length
        max_length = schema.value.max_length
      }
    }
  }

  ## Policies : What password strength do you want to require?
  ## Conditionally add password_policy block if password_policy variable is defined
  dynamic "password_policy" {
    for_each = var.password_policy != null ? [var.password_policy] : []

    content {
      minimum_length                   = password_policy.value.minimum_length
      require_lowercase                = password_policy.value.require_lowercase
      require_numbers                  = password_policy.value.require_numbers
      require_symbols                  = password_policy.value.require_symbols
      require_uppercase                = password_policy.value.require_uppercase
      temporary_password_validity_days = password_policy.value.temporary_password_validity_days
    }
  }

  ## MFA and verifications : Do you want to enable Multi-Factor Authentication (MFA)?
  mfa_configuration = var.mfa_configuration
  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration == "OFF" ? [] : [1]

    content {
      enabled = var.mfa_software_token
    }
  }

  ## Conditionally enable account recovery setting using dynamic block, but only 1 account_recovery_setting block
  dynamic "account_recovery_setting" {
    for_each = var.enable_account_recovery && length(var.account_recovery_mechanisms) > 0 ? [1] : []

    content {
      dynamic "recovery_mechanism" {
        for_each = var.account_recovery_mechanisms
        content {
          name     = recovery_mechanism.value.name
          priority = recovery_mechanism.value.priority
        }
      }
    }
  }

  # ## Triggers : Lambda
  dynamic "lambda_config" {
    for_each = var.lambda_post_auth != "" ? [1] : []

    content {
      post_authentication = var.lambda_post_auth
      # Only add pre_token_generation if needed
      pre_token_generation = var.lambda_pre_token_generation != "" ? var.lambda_pre_token_generation : null
    }
  }

}

## Create "AppClients" for the application
resource "aws_cognito_user_pool_client" "appclient" {
  count        = var.enable_module ? 1 : 0  
  name         = "${var.environment}-${var.app_client_name}-${random_id.this[count.index].hex}"
  user_pool_id = aws_cognito_user_pool.pool[count.index].id

  token_validity_units {
    access_token  = "days"
    id_token      = "days"
    refresh_token = "days"
  }
}
