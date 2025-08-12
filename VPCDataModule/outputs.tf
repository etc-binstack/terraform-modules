# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = var.enable_module ? data.aws_vpc.this[*].id : null
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.enable_module ? data.aws_vpc.this[*].cidr_block : null
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = var.enable_module ? data.aws_vpc.this[*].arn : null
}

# Subnet Information
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = var.enable_module ? [for subnet in data.aws_subnet.public : subnet.id] : []
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = var.enable_module ? [for subnet in data.aws_subnet.private : subnet.id] : []
}

output "isolated_subnet_ids" {
  description = "List of isolated subnet IDs"
  value       = var.enable_module ? [for subnet in data.aws_subnet.isolated : subnet.id] : []
}

output "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  value       = var.enable_module ? [for subnet in data.aws_subnet.public : subnet.cidr_block] : []
}

output "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  value       = var.enable_module ? [for subnet in data.aws_subnet.private : subnet.cidr_block] : []
}

output "isolated_subnet_cidr_blocks" {
  description = "List of isolated subnet CIDR blocks"
  value       = var.enable_module ? [for subnet in data.aws_subnet.isolated : subnet.cidr_block] : []
}

# Availability Zone Information
output "public_subnet_availability_zones" {
  description = "List of availability zones for public subnets"
  value       = local.public_subnet_azs
}

output "private_subnet_availability_zones" {
  description = "List of availability zones for private subnets"
  value       = local.private_subnet_azs
}

output "isolated_subnet_availability_zones" {
  description = "List of availability zones for isolated subnets"
  value       = local.isolated_subnet_azs
}

# Gateway Information
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = local.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = var.enable_module && var.lookup_nat_gateways ? [for ngw in data.aws_nat_gateway.this : ngw.id] : []
}

output "nat_gateway_public_ips" {
  description = "List of public IPs associated with the NAT Gateways"
  value       = var.enable_module && var.lookup_nat_gateways ? [for ngw in data.aws_nat_gateway.this : ngw.public_ip] : []
}

# Route Table Information
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.enable_module && var.lookup_route_tables ? try(data.aws_route_table.public[0].id, null) : null
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = var.enable_module && var.lookup_route_tables ? try(data.aws_route_table.private[0].id, null) : null
}

output "isolated_route_table_id" {
  description = "ID of the isolated route table"
  value       = var.enable_module && var.lookup_route_tables ? try(data.aws_route_table.isolated[0].id, null) : null
}

# Database Information
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = var.enable_module && var.lookup_db_subnet_group ? try(data.aws_db_subnet_group.this[0].name, null) : null
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = var.enable_module && var.lookup_db_subnet_group ? try(data.aws_db_subnet_group.this[0].arn, null) : null
}

# Security Group Information
output "default_security_group_id" {
  description = "ID of the default security group"
  value       = var.enable_module ? data.aws_security_group.default[0].id : null
}

# Subnet Counts
output "subnet_counts" {
  description = "Count of subnets by type"
  value = var.enable_module ? {
    public   = local.public_subnet_count
    private  = local.private_subnet_count
    isolated = local.isolated_subnet_count
    total    = local.public_subnet_count + local.private_subnet_count + local.isolated_subnet_count
  } : null
}

# Regional Information
output "region" {
  description = "AWS region"
  value       = var.enable_module ? data.aws_region.current[0].name : null
}

output "availability_zones" {
  description = "List of availability zones in the region"
  value       = var.enable_module ? data.aws_availability_zones.available[0].names : []
}