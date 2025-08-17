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

## IAM Role for Pre-Token-Generation Lambda
resource "aws_iam_role" "pre_token_lambda_role" {
  count = var.enable_module && var.enable_multi_tenant_saas ? 1 : 0
  name  = "${var.environment}-pre-token-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "pre_token_lambda_logs" {
  count      = var.enable_module && var.enable_multi_tenant_saas ? 1 : 0
  role       = aws_iam_role.pre_token_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

## Pre-Token-Generation Lambda Code
data "archive_file" "pre_token_zip" {
  count       = var.enable_module && var.enable_multi_tenant_saas ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/pre_token_lambda.zip"

  source {
    content  = <<EOF
exports.handler = async (event) => {
  const claims = {};
  ${join("\n  ", [for claim in var.jwt_custom_claims : "claims['${claim}'] = event.request.userAttributes['custom:${claim}'] || null;"])}
  event.response = {
    claimsAndScopeOverrideDetails: {
      idTokenGeneration: {
        claimsToAddOrOverride: claims,
        claimsToSuppress: []
      },
      accessTokenGeneration: {
        claimsToAddOrOverride: claims,
        claimsToSuppress: [],
        scopesToAdd: [],
        scopesToSuppress: []
      },
      groupOverrideDetails: {
        groupsToOverride: event.request.groupConfiguration.groupsToOverride || [],
        iamRolesToOverride: event.request.groupConfiguration.iamRolesToOverride || [],
        preferredRole: event.request.groupConfiguration.preferredRole || ''
      }
    }
  };
  return event;
};
EOF
    filename = "index.js"
  }
}

## Pre-Token-Generation Lambda Function
resource "aws_lambda_function" "pre_token" {
  count         = var.enable_module && var.enable_multi_tenant_saas ? 1 : 0
  function_name = "${var.environment}-pre-token-gen"
  role          = aws_iam_role.pre_token_lambda_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.pre_token_zip[0].output_path
  source_code_hash = data.archive_file.pre_token_zip[0].output_base64sha256

  tags = var.tags
}

## Permission for Cognito to Invoke Lambda
resource "aws_lambda_permission" "allow_cognito_invoke" {
  count         = var.enable_module && var.enable_multi_tenant_saas ? 1 : 0
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_token[0].function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.pool[0].arn
}

##################################
### RESOURCE MODULE: USER POOL  
##################################

## Create cognito pool id
resource "aws_cognito_user_pool" "pool" {
  count = var.enable_module ? 1 : 0
  name  = "${var.environment}-${var.cognito_pool_name}-${random_id.this[0].hex}"

  ## Attributes : How do you want your end users to sign in? email for sign-in (optional) and set auto-verified attributes
  username_attributes      = length(var.sign_in_attribute) > 0 ? var.sign_in_attribute : null
  auto_verified_attributes = length(var.auto_verified_attributes) > 0 ? var.auto_verified_attributes : null
  deletion_protection      = var.deletion_protection

  username_configuration {
    case_sensitive = var.case_sensitive_username
  }

  ## Email Schema
  dynamic "schema" {
    for_each = var.enable_email_schema ? [var.email_schema_constraints] : []
    content {
      name                     = "email"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = schema.value.mutable
      required                 = schema.value.required
      string_attribute_constraints {
        min_length = schema.value.min_length
        max_length = schema.value.max_length
      }
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
  ## Password Policy
  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = var.password_policy.require_lowercase
    require_numbers                  = var.password_policy.require_numbers
    require_symbols                  = var.password_policy.require_symbols
    require_uppercase                = var.password_policy.require_uppercase
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
  }

  ## MFA and verifications : Do you want to enable Multi-Factor Authentication (MFA)?
  mfa_configuration = var.mfa_configuration
  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration == "OFF" ? [] : [1]
    content {
      enabled = var.mfa_software_token
    }
  }

  ## SMS MFA Configuration
  dynamic "sms_configuration" {
    for_each = var.enable_sms_mfa && var.sms_configuration != null ? [var.sms_configuration] : []
    content {
      sns_caller_arn = sms_configuration.value.sns_caller_arn
      external_id    = sms_configuration.value.external_id
    }
  }
  
  ## Conditionally enable account recovery setting using dynamic block, but only 1 account_recovery_setting block
  ## Account Recovery
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

  ## Lambda Triggers
  dynamic "lambda_config" {
    for_each = var.enable_module && (anytrue([for k, v in var.lambda_triggers : v != ""]) || var.enable_multi_tenant_saas) ? [1] : []
    content {
      pre_sign_up           = var.lambda_triggers.pre_sign_up != "" ? var.lambda_triggers.pre_sign_up : null
      post_confirmation     = var.lambda_triggers.post_confirmation != "" ? var.lambda_triggers.post_confirmation : null
      post_authentication   = var.lambda_triggers.post_authentication != "" ? var.lambda_triggers.post_authentication : null
      pre_token_generation  = var.enable_multi_tenant_saas ? aws_lambda_function.pre_token[0].arn : (var.lambda_triggers.pre_token_generation != "" ? var.lambda_triggers.pre_token_generation : null)
      custom_message        = var.lambda_triggers.custom_message != "" ? var.lambda_triggers.custom_message : null
    }
  }

  tags = var.tags
}

## App Clients
resource "aws_cognito_user_pool_client" "appclient" {
  count        = var.enable_module ? length(var.app_clients) : 0
  name         = "${var.environment}-${var.app_clients[count.index].name}-${random_id.this[0].hex}"
  user_pool_id = aws_cognito_user_pool.pool[0].id
  callback_urls        = var.app_clients[count.index].callback_urls
  logout_urls          = var.app_clients[count.index].logout_urls
  allowed_oauth_flows  = var.app_clients[count.index].allowed_oauth_flows
  allowed_oauth_scopes = var.app_clients[count.index].allowed_oauth_scopes
  generate_secret      = var.app_clients[count.index].generate_secret
  read_attributes      = var.app_clients[count.index].read_attributes
  write_attributes     = var.app_clients[count.index].write_attributes

  access_token_validity  = var.app_clients[count.index].access_token_validity
  id_token_validity      = var.app_clients[count.index].id_token_validity
  refresh_token_validity = var.app_clients[count.index].refresh_token_validity

  token_validity_units {
    access_token  = var.app_clients[count.index].token_validity_units
    id_token      = var.app_clients[count.index].token_validity_units
    refresh_token = var.app_clients[count.index].token_validity_units
  }
}

## User Groups
resource "aws_cognito_user_pool_group" "groups" {
  count        = var.enable_module && var.enable_user_groups ? length(var.user_groups) : 0
  name         = var.user_groups[count.index]
  user_pool_id = aws_cognito_user_pool.pool[0].id
  tags         = var.tags
}

## Identity Providers
resource "aws_cognito_identity_provider" "idp" {
  count        = var.enable_module && var.enable_identity_providers ? length(var.identity_providers) : 0
  user_pool_id = aws_cognito_user_pool.pool[0].id
  provider_name = var.identity_providers[count.index].provider_name
  provider_type = var.identity_providers[count.index].provider_type
  provider_details = var.identity_providers[count.index].provider_details
  attribute_mapping = var.identity_providers[count.index].attribute_mapping
}

## Resource Servers
resource "aws_cognito_resource_server" "resource_server" {
  count        = var.enable_module && var.enable_resource_servers ? length(var.resource_servers) : 0
  user_pool_id = aws_cognito_user_pool.pool[0].id
  name         = var.resource_servers[count.index].name
  identifier   = var.resource_servers[count.index].identifier

  dynamic "scope" {
    for_each = var.resource_servers[count.index].scopes
    content {
      scope_name        = scope.value.scope_name
      scope_description = scope.value.scope_description
    }
  }
}

## Domain Configuration
resource "aws_cognito_user_pool_domain" "domain" {
  count           = var.enable_module && var.enable_domain && var.domain_config != null ? 1 : 0
  domain          = var.domain_config.domain
  certificate_arn = var.domain_config.certificate_arn
  user_pool_id    = aws_cognito_user_pool.pool[0].id
}