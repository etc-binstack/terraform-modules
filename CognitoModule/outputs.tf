##################################
### Output - Cognito User Pool
##################################

output "cognito_user_pool_id" {
  description = "The ID of the created Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[*].id : null
}

output "cognito_user_pool_name" {
  description = "The name of the created Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[*].name : null
}

output "cognito_user_pool_arn" {
  description = "The ARN of the created Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[*].arn : null
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito App Client"
  value       = var.enable_module ? aws_cognito_user_pool_client.appclient[*].id : null
}

output "cognito_user_pool_client_name" {
  description = "The name of the Cognito App Client"
  value       = var.enable_module ? aws_cognito_user_pool_client.appclient[*].name : null
}

output "cognito_user_pool_client_secret" {
  description = "The secret associated with the Cognito App Client"
  value       = var.enable_module ? aws_cognito_user_pool_client.appclient[*].client_secret : null
}

output "mfa_configuration" {
  description = "The MFA configuration of the Cognito User Pool"
  value       = var.enable_module ? aws_cognito_user_pool.pool[*].mfa_configuration : null
}

output "lambda_post_auth_trigger" {
  description = "The ARN of the post-authentication Lambda function, if configured"
  value       = var.enable_module ? (var.lambda_post_auth != "" ? var.lambda_post_auth : "None") : null
}

output "account_recovery_mechanisms" {
  description = "The account recovery mechanisms for the Cognito User Pool"
  value       = var.enable_module ? var.account_recovery_mechanisms : null
}

