output "api_id" {
  description = "ID of the API Gateway REST API"
  value       = var.enable_module ? aws_api_gateway_rest_api.apigw[0].id : null
}

output "api_arn" {
  description = "ARN of the API Gateway REST API"
  value       = var.enable_module ? aws_api_gateway_rest_api.apigw[0].arn : null
}

output "invoke_url" {
  description = "Invoke URL of the stage"
  value       = var.enable_module ? aws_api_gateway_stage.apigw[0].invoke_url : null
}

output "custom_domain" {
  description = "Custom domain name"
  value       = var.enable_custom_domain && var.enable_module ? aws_api_gateway_domain_name.apigw[0].domain_name : null
}

output "api_key_value" {
  description = "Value of the API key (sensitive)"
  value       = var.enable_api_key && var.enable_module ? aws_api_gateway_api_key.apigw[0].value : null
  sensitive   = true
}