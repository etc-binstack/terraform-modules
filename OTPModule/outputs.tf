## File: outputs.tf
##============================
## Module Outputs
##============================
output "lambda_generate_otp_function_name" {
  description = "Name of the generate OTP Lambda function"
  value       = var.enable_module ? aws_lambda_function.generate_otp[0].function_name : null
}

output "lambda_verify_otp_function_name" {
  description = "Name of the verify OTP Lambda function"
  value       = var.enable_module ? aws_lambda_function.verify_otp[0].function_name : null
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = var.enable_module ? aws_dynamodb_table.otp_table[0].name : null
}

output "kms_primary_key_arn" {
  description = "ARN of the primary KMS key"
  value       = var.enable_module ? aws_kms_key.primary_key[0].arn : null
}

output "kms_replica_key_arn" {
  description = "ARN of the replica KMS key"
  value       = var.enable_module && var.enable_multi_region ? aws_kms_replica_key.replica_key[0].arn : null
}

output "primary_api_gateway_url" {
  description = "URL of the primary API Gateway"
  value       = var.enable_module ? "${aws_api_gateway_deployment.otp_api[0].invoke_url}" : null
}

output "replica_api_gateway_url" {
  description = "URL of the replica API Gateway"
  value       = var.enable_module && var.enable_multi_region ? "${aws_api_gateway_deployment.otp_api_replica[0].invoke_url}" : null
}