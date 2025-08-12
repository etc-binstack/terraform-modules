```yml
# Get current AWS region and availability zones
data "aws_region" "current" {
  count = var.enable_module ? 1 : 0
}

data "aws_availability_zones" "available" {
  count = var.enable_module ? 1 : 0
  state = "available"
}

# VPC data source with validation
data "aws_vpc" "this" {
  count = var.enable_module ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  lifecycle {
    postcondition {
      condition     = length(self.id) > 0
      error_message = "VPC with ID '${var.vpc_id}' not found in region. Please verify the VPC ID and AWS region are correct."
    }
  }
}

# Default security group
data "aws_security_group" "default" {
  count  = var.enable_module ? 1 : 0
  vpc_id = data.aws_vpc.this[0].id
  name   = "default"
}

# Public subnets with validation
data "aws_subnet" "public" {
  count = var.enable_module ? length(var.public_subnet_ids) : 0
  
  filter {
    name   = "subnet-id"
    values = [var.public_subnet_ids[count.index]]
  }
  
  lifecycle {
    postcondition {
      condition     = length(self.id) > 0
      error_message = "Public subnet with ID '${var.public_subnet_ids[count.index]}' not found. Please verify the subnet ID and AWS region are correct."
    }
  }
}

# Private subnets with validation
data "aws_subnet" "private" {
  count = var.enable_module ? length(var.private_subnet_ids) : 0
  
  filter {
    name   = "subnet-id"
    values = [var.private_subnet_ids[count.index]]
  }
  
  lifecycle {
    postcondition {
      condition     = length(self.id) > 0
      error_message = "Private subnet with ID '${var.private_subnet_ids[count.index]}' not found. Please verify the subnet ID and AWS region are correct."
    }
  }
}

# Isolated subnets with validation
data "aws_subnet" "isolated" {
  count = var.enable_module ? length(var.isolated_subnet_ids) : 0
  
  filter {
    name   = "subnet-id"
    values = [var.isolated_subnet_ids[count.index]]
  }
  
  lifecycle {
    postcondition {
      condition     = length(self.id) > 0
      error_message = "Isolated subnet with ID '${var.isolated_subnet_ids[count.index]}' not found. Please verify the subnet ID and AWS region are correct."
    }
  }
}

# Internet Gateway - lookup by ID if provided
data "aws_internet_gateway" "by_id" {
  count = var.enable_module && var.internet_gateway_id != null ? 1 : 0
  
  filter {
    name   = "internet-gateway-id"
    values = [var.internet_gateway_id]
  }
  
  lifecycle {
    postcondition {
      condition     = length(self.id) > 0
      error_message = "Internet Gateway with ID '${var.internet_gateway_id}' not found. Please verify the IGW ID and AWS region are correct."
    }
  }
}

# Internet Gateway - lookup by name tag if provided
data "aws_internet_gateway" "by_name" {
  count = var.enable_module && var.internet_gateway_name_tag != null ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.internet_gateway_name_tag]
  }

  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.this[0].id]
  }
}

# NAT Gateways - get all NAT gateways in the VPC
data "aws_nat_gateways" "this" {
  count  = var.enable_module && var.lookup_nat_gateways ? 1 : 0
  vpc_id = data.aws_vpc.this[0].id
}

data "aws_nat_gateway" "this" {
  count = var.enable_module && var.lookup_nat_gateways ? length(local.nat_gateway_ids) : 0
  id    = local.nat_gateway_ids[count.index]
}

# Route Tables
data "aws_route_table" "public" {
  count  = var.enable_module && var.lookup_route_tables ? 1 : 0
  vpc_id = data.aws_vpc.this[0].id

  tags = {
    Name = "${var.environment}-${var.route_table_name_prefix}-pub-rtb"
  }
}

data "aws_route_table" "private" {
  count  = var.enable_module && var.lookup_route_tables ? 1 : 0
  vpc_id = data.aws_vpc.this[0].id

  tags = {
    Name = "${var.environment}-${var.route_table_name_prefix}-priv-rtb"
  }
}

data "aws_route_table" "isolated" {
  count  = var.enable_module && var.lookup_route_tables ? 1 : 0
  vpc_id = data.aws_vpc.this[0].id

  tags = {
    Name = "${var.environment}-${var.route_table_name_prefix}-isol-rtb"
  }
}

# DB Subnet Group
data "aws_db_subnet_group" "this" {
  count = var.enable_module && var.lookup_db_subnet_group && var.db_subnet_group_name != null ? 1 : 0
  name  = var.db_subnet_group_name
}
```