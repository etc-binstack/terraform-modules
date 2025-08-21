# Primary outputs
output "vpc_link_id" {
  description = "The identifier of the VPC Link"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].id : null
}

output "vpc_link_name" {
  description = "The name of the VPC Link"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].name : null
}

output "vpc_link_arn" {
  description = "The ARN of the VPC Link"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].arn : null
}

output "vpc_link_description" {
  description = "The description of the VPC Link"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].description : null
}

output "vpc_link_target_arns" {
  description = "The target ARNs of the VPC Link"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].target_arns : null
}

output "vpc_link_tags" {
  description = "The tags assigned to the VPC Link"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].tags_all : null
}

# Additional useful outputs
output "vpc_link_state" {
  description = "The state of the VPC Link"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].state : null
}

output "random_suffix" {
  description = "The random suffix used in the VPC Link name (if enabled)"
  value       = var.enable_module && var.use_random_suffix ? random_string.this[0].result : null
}

output "target_nlb_details" {
  description = "Details of the target Network Load Balancers"
  value = var.enable_module ? [
    for nlb in data.aws_lb.target_nlbs : {
      arn                = nlb.arn
      name              = nlb.name
      dns_name          = nlb.dns_name
      hosted_zone_id    = nlb.zone_id
      load_balancer_type = nlb.load_balancer_type
      scheme            = nlb.scheme
      vpc_id            = nlb.vpc_id
    }
  ] : []
}

# Legacy output for backward compatibility
output "vpclink_id" {
  description = "(DEPRECATED) Use vpc_link_id instead"
  value       = var.enable_module ? aws_api_gateway_vpc_link.vpclink[0].id : null
}

# Module metadata
output "module_enabled" {
  description = "Whether the VPC Link module is enabled"
  value       = var.enable_module
}

output "computed_name" {
  description = "The computed name used for the VPC Link"
  value       = var.enable_module ? local.vpc_link_name : null
}
