## VPC ID
output "vpc_id" {
  value = var.enable_module ? data.aws_vpc.existing_vpc[*].id : null
}

## VPC CIDR range
output "vpc_cidr" {
  value = var.enable_module ? data.aws_vpc.existing_vpc[*].cidr_block : null
}

## Public Subnet IDs
output "public_subnet_ids" {
  value = var.enable_module && length(data.aws_subnet.public) > 0 ? [for subnet in data.aws_subnet.public : subnet.id] : null
}

## Private Subnet IDs
output "private_subnet_ids" {
  value = var.enable_module && length(data.aws_subnet.private) > 0 ? [for subnet in data.aws_subnet.private : subnet.id] : null
}

## Isolated Subnet IDs
output "isolated_subnet_ids" {
  value = var.enable_module && length(data.aws_subnet.isolated) > 0 ? [for subnet in data.aws_subnet.isolated : subnet.id] : null
}

## Internet Gateway ID
output "internet_gateway_id" {
  value = var.enable_module ? data.aws_internet_gateway.igw[*].id : null
}

## NAT Gateway IDs
output "nat_gateway_ids" {
  value = var.enable_module && length(data.aws_nat_gateway.ngw) > 0 ? [for ngw in data.aws_nat_gateway.ngw : ngw.id] : null
}

## Route Table IDs for Public Subnets
output "public_route_table_id" {
  value = var.enable_module && length(data.aws_route_table.public) > 0 ? [for rt in data.aws_route_table.public : rt.id] : null
}

## Route Table IDs for Private Subnets
output "private_route_table_ids" {
  value = var.enable_module && length(data.aws_route_table.private) > 0 ? [for rt in data.aws_route_table.private : rt.id] : null
}

## Route Table IDs for Isolated Subnets
output "isolated_route_table_ids" {
  value = var.enable_module && length(data.aws_route_table.isolated) > 0 ? [for rt in data.aws_route_table.isolated : rt.id] : null
}

## DB Subnet Group Name (if enabled)
output "db_subnet_group_name" {
  description = "The name of the DB Subnet Group (if enabled)"
  value       = var.enable_module && data.aws_db_subnet_group.subnet_group != null ? data.aws_db_subnet_group.subnet_group[*].name : null
}
