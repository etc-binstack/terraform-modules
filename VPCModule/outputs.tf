## VPC ID
output "vpc_id" {
  value = var.enable_module ? aws_vpc.vpc[*].id : null
}

## VPC CIDR range
output "vpc_cidr" {
  value = var.enable_module ? aws_vpc.vpc[*].cidr_block : null
}

## Public Subnet IDs
output "public_subnet_ids" {
  value = var.enable_module ? aws_subnet.public[*].id : null
}

## Private Subnet IDs
output "private_subnet_ids" {
  value = var.enable_module ? aws_subnet.private[*].id : null
}

## Isolated Subnet IDs
output "isolated_subnet_ids" {
  value = var.enable_module ? aws_subnet.isolated[*].id : null
}

## Internet Gateway ID
output "internet_gateway_id" {
  value = var.enable_module ? aws_internet_gateway.igw[*].id : null
}

## NAT Gateway IDs
output "nat_gateway_ids" {
  value = var.enable_module ? aws_nat_gateway.ngw[*].id : null
}

## Route Table IDs for Public Subnets
output "public_route_table_id" {
  value = var.enable_module ? aws_route_table.public[*].id : null
}

## Route Table IDs for Private Subnets
output "private_route_table_ids" {
  value = var.enable_module ? aws_route_table.private[*].id : null
}

## Route Table IDs for Isolated Subnets
output "isolated_route_table_ids" {
  value = var.enable_module ? aws_route_table.isolated_rtb[*].id : null
}

## VPC Flow Logs Log Group ARN (if enabled)
output "vpc_flowlogs_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for VPC Flow Logs (if enabled)"
  value       = var.enable_module && var.vpc_flowlogs_enable ? aws_cloudwatch_log_group.flowlogs[*].arn : null
}

## DB Subnet Group Name (if enabled)
output "db_subnet_group_name" {
  description = "The name of the DB Subnet Group (if enabled)"
  value       = var.enable_module && var.db_subnetgroup_enable ? aws_db_subnet_group.subnet_group[*].name : null
}

output "priv_subnet_cidr" {
  description = "Priv Subnet CIDR"
  value       = var.enable_module ? aws_subnet.private[*].cidr_block : null

}