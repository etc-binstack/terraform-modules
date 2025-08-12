############################################
## VPC Configuration 
############################################

## Fetch existing AZs in the current region
data "aws_availability_zones" "available" {}

## Fetch existing VPC
data "aws_vpc" "existing_vpc" {
  count = var.enable_module ? 1 : 0
  id = var.existing_vpc_id
}

## Fetch existing security group
data "aws_security_group" "default" {
  count = var.enable_module ? 1 : 0   
  vpc_id = data.aws_vpc.existing_vpc[count.index].id
  name   = "default"
}

############################################
## Fetch: Subnets 
############################################
## Fetch existing public subnets
data "aws_subnet" "public" {
  count = var.enable_module && var.az_count > 0 ? var.az_count : 0
  id    = var.existing_public_subnet_ids[count.index]
}

## Fetch existing private subnets
data "aws_subnet" "private" {
  count = var.enable_module && var.az_count > 0 ? var.az_count : 0
  id    = var.existing_private_subnet_ids[count.index]
}

## Fetch existing isolated subnets
data "aws_subnet" "isolated" {
  count = var.enable_module && var.az_count > 0 ? var.az_count : 0
  id    = var.existing_isolated_subnet_ids[count.index]
}

############################################
## Fetch existingC Routetable
############################################
## Fetch existing Internet Gateway by ID
data "aws_internet_gateway" "igw" {
  count = var.enable_module ? 1 : 0

  filter {
    name   = "tag:Name"   # Use tag:Name to filter by the Name tag
    values = ["${var.environment}-${existing_vpc_tagname}"]  # The name tag value (environment-based name)
  }

  filter {
    name   = "attachment.vpc-id"  # Filter by the VPC ID where the IGW is attached
    values = [data.aws_vpc.existing_vpc[0].id]
  }
}

## Fetch existing NAT Gateway
data "aws_nat_gateway" "ngw" {
  count = var.enable_module && length(data.aws_subnet.public) > 0 ? 1 : 0
  subnet_id = element(data.aws_subnet.public.*.id, 0)
}

## Fetch existing route tables
data "aws_route_table" "public" {
  count = var.enable_module ? 1 : 0   
  vpc_id = data.aws_vpc.existing_vpc[0].id
  tags = {
    Name = "${var.environment}-${existing_vpc_tagname}"
  }
}

data "aws_route_table" "private" {
  count = var.enable_module ? 1 : 0   
  vpc_id = data.aws_vpc.existing_vpc[0].id
  tags = {
    Name = "${var.environment}-${existing_vpc_tagname}"
  }
}

## Fetch existing isolated route table
data "aws_route_table" "isolated" {
  count = var.enable_module ? 1 : 0  
  vpc_id = data.aws_vpc.existing_vpc[0].id
  tags = {
    Name = "${var.environment}-${existing_vpc_tagname}"
  }
}

########################################
## Fetch existing DB Subnet Group if needed
########################################
data "aws_db_subnet_group" "subnet_group" {
  count = var.enable_module ? 1 : 0
  name = var.db_subnet_group_name
}