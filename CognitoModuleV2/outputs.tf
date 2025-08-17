##################################
### Output - Cognito User Pool
##################################

output "cognito_user_pool_id" {
  description = "The ID of the created Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[0].id : null
}

output "cognito_user_pool_name" {
  description = "The name of the created Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[0].name : null
}

output "cognito_user_pool_arn" {
  description = "The ARN of the created Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[0].arn : null
}

output "cognito_user_pool_client_ids" {
  description = "List of IDs for the Cognito App Clients"
  value       = var.enable_module ? aws_cognito_user_pool_client.appclient[*].id : []
}

output "cognito_user_pool_client_names" {
  description = "List of names for the Cognito App Clients"
  value       = var.enable_module ? aws_cognito_user_pool_client.appclient[*].name : []
}

output "cognito_user_pool_client_secrets" {
  description = "List of secrets for the Cognito App Clients"
  value       = var.enable_module ? aws_cognito_user_pool_client.appclient[*].client_secret : []
  sensitive   = true
}

output "mfa_configuration" {
  description = "The MFA configuration of the Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[0].mfa_configuration : null
}

output "lambda_triggers" {
  description = "Map of configured Lambda trigger ARNs"
  value       = var.enable_module ? merge(var.lambda_triggers, {
    pre_token_generation = var.enable_multi_tenant_saas ? aws_lambda_function.pre_token[0].arn : var.lambda_triggers.pre_token_generation
  }) : {}
}

output "account_recovery_mechanisms" {
  description = "The account recovery mechanisms for the Cognito User Pool"
  value       = var.enable_module ? var.account_recovery_mechanisms : []
}

output "user_group_names" {
  description = "List of created user group names"
  value       = var.enable_module && var.enable_user_groups ? aws_cognito_user_pool_group.groups[*].name : []
}

output "identity_provider_names" {
  description = "List of configured identity provider names"
  value       = var.enable_module && var.enable_identity_providers ? aws_cognito_identity_provider.idp[*].provider_name : []
}

output "resource_server_identifiers" {
  description = "List of configured resource server identifiers"
  value       = var.enable_module && var.enable_resource_servers ? aws_cognito_resource_server.resource_server[*].identifier : []
}

output "user_pool_domain" {
  description = "The custom domain for the Cognito User Pool"
  value       = var.enable_module && var.enable_domain ? aws_cognito_user_pool_domain.domain[0].domain : null
}

output "pre_token_lambda_arn" {
  description = "ARN of the pre-token-generation Lambda function (if created)"
  value       = var.enable_module && var.enable_multi_tenant_saas ? aws_lambda_function.pre_token[0].arn : null
}