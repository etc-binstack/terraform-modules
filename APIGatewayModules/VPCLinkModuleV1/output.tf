output "vpc_link_id" {
  value = var.enable_module ? aws_api_gateway_vpc_link.vpclink[*].id : null
}