############################################
## VPC Configuration 
############################################

## fetch AZs in the current region
data "aws_availability_zones" "available" {
}

## Create: VPC
resource "aws_vpc" "vpc" {
  count                = var.enable_module ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = var.tags
}

## Default Security-Group (ensure that default security group should be restricts all traffic)
resource "aws_default_security_group" "default" {
  count  = var.enable_module ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
}

############################################
## Create: Subnets 
############################################
resource "aws_subnet" "public" {
  count                                       = var.enable_module && var.az_count > 0 ? var.az_count : 0
  cidr_block                                  = cidrsubnet(aws_vpc.vpc[0].cidr_block, var.subnet_cidr_block, count.index)
  availability_zone                           = data.aws_availability_zones.available.names[count.index]
  vpc_id                                      = aws_vpc.vpc[0].id
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-pub-sub-${count.index}" })
}

resource "aws_subnet" "private" {
  count                                       = var.enable_module && var.az_count > 0 ? var.az_count : 0
  cidr_block                                  = cidrsubnet(aws_vpc.vpc[0].cidr_block, var.subnet_cidr_block, var.az_count + count.index)
  availability_zone                           = data.aws_availability_zones.available.names[count.index]
  vpc_id                                      = aws_vpc.vpc[0].id
  enable_resource_name_dns_a_record_on_launch = true

  tags = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-priv-sub-${count.index}" })
}

resource "aws_subnet" "isolated" {
  count                                       = var.enable_module && var.az_count > 0 ? var.az_count : 0
  cidr_block                                  = cidrsubnet(aws_vpc.vpc[0].cidr_block, var.subnet_cidr_block, var.az_count + 1 + (count.index + 1))
  availability_zone                           = data.aws_availability_zones.available.names[count.index]
  vpc_id                                      = aws_vpc.vpc[0].id
  enable_resource_name_dns_a_record_on_launch = true

  tags = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-isol-sub-${count.index}" })
}

############################################
## Create: PUBLIC Routetable
############################################
## Create IGW
resource "aws_internet_gateway" "igw" {
  count  = var.enable_module ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-igw" })
}

## Create Routetable
resource "aws_route_table" "public" {
  count  = var.enable_module ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.igw[0].id
  # }
  tags = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-pub-rtb" })
}

resource "aws_route" "public_igw" {
  count                  = var.enable_module ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route" "public_pcx" {
  count                     = var.enable_module && var.enable_peering_route && length(var.pcx_routes) > 0 ? length(var.pcx_routes) : 0
  route_table_id            = aws_route_table.public[0].id
  destination_cidr_block    = var.pcx_routes[count.index].cidr_block
  vpc_peering_connection_id = var.pcx_routes[count.index].vpc_peering_id
}

## Routetable Associate (public subnets)
resource "aws_route_table_association" "public" {
  count          = var.enable_module && var.az_count > 0 ? var.az_count : 0
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

############################################
## Create: Private Routetable
############################################
## To avoid repeating complex ternary logic everywhere, define a local variable:
locals {
  natgw_count = var.enable_module ? (
    var.environment == "prod" && var.environment_alias != "DRsite" ? var.az_count : 1
  ) : 0

  natgw_count_tag_allocation = var.environment == "prod" && var.environment_alias != "DRsite"
}

## Create Elasic IPs (NAT gateway)
resource "aws_eip" "ngw_eip" {
  # count      = var.enable_module ? (var.environment == "prod" && var.environment_alias != "DRsite" ? var.az_count : 1) : 0
  count      = local.natgw_count
  tags       = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-ngw-eip-${count.index}" })
  depends_on = [aws_internet_gateway.igw]
}

## Create NAT gateway
resource "aws_nat_gateway" "ngw" {
  count             = local.natgw_count
  subnet_id         = element(aws_subnet.public.*.id, count.index)
  allocation_id     = element(aws_eip.ngw_eip.*.id, local.natgw_count_tag_allocation ? count.index : 0)
  connectivity_type = "public"

  tags       = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-ngw-${count.index}" })
  depends_on = [aws_internet_gateway.igw]
}

## Create Routetable
resource "aws_route_table" "private" {
  count  = local.natgw_count
  vpc_id = aws_vpc.vpc[0].id
  tags   = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-priv-rtb${local.natgw_count_tag_allocation ? "-${count.index}" : ""}" })
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = var.environment == "prod" ? element(aws_nat_gateway.ngw.*.id, count.index) : element(aws_nat_gateway.ngw.*.id, 0)
  # }  
}

resource "aws_route" "private_ngw" {
  count                  = local.natgw_count
  route_table_id         = local.natgw_count_tag_allocation ? element(aws_route_table.private.*.id, count.index) : element(aws_route_table.private.*.id, 0)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.natgw_count_tag_allocation ? element(aws_nat_gateway.ngw.*.id, count.index) : element(aws_nat_gateway.ngw.*.id, 0)
}

resource "aws_route" "private_pcx" {
  count = var.enable_module && var.enable_peering_route && length(var.pcx_routes) > 0 ? (
    local.natgw_count_tag_allocation ? (var.az_count * length(var.pcx_routes)) : length(var.pcx_routes)
  ) : 0

  route_table_id = local.natgw_count_tag_allocation ? (
    element(aws_route_table.private.*.id, floor(count.index / length(var.pcx_routes)))
  ) : aws_route_table.private[0].id

  destination_cidr_block    = var.pcx_routes[count.index % length(var.pcx_routes)].cidr_block
  vpc_peering_connection_id = var.pcx_routes[count.index % length(var.pcx_routes)].vpc_peering_id
}

## Routetable Associate (public subnets)
resource "aws_route_table_association" "private" {
  count          = var.enable_module && var.az_count > 0 ? var.az_count : 0
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = local.natgw_count_tag_allocation ? element(aws_route_table.private.*.id, count.index) : aws_route_table.private[0].id

  # lifecycle {
  #   ignore_changes = [
  #     # List the attributes you want to ignore here, for example:
  #     subnet_id,
  #     route_table_id,
  #   ]
  # }
}

############################################
## Create: Isolated routetable
############################################

resource "aws_route_table" "isolated_rtb" {
  count  = var.enable_module ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = merge(var.tags, { Name = "${var.environment}-${var.vpc_name_prefix}-isol-rtb" })
}

resource "aws_route" "isolated_pcx" {
  count                     = var.enable_module && var.enable_peering_route && length(var.pcx_routes) > 0 ? length(var.pcx_routes) : 0
  route_table_id            = aws_route_table.isolated_rtb[0].id
  destination_cidr_block    = var.pcx_routes[count.index].cidr_block
  vpc_peering_connection_id = var.pcx_routes[count.index].vpc_peering_id
}

## Associate routetable with subnets
resource "aws_route_table_association" "isolated_rtb_association" {
  count          = var.enable_module && var.az_count > 0 ? var.az_count : 0
  subnet_id      = element(aws_subnet.isolated.*.id, count.index)
  route_table_id = aws_route_table.isolated_rtb[0].id
}


########################################
##  Database (RDS) Subnet Group 
########################################
resource "aws_db_subnet_group" "subnet_group" {
  count      = var.enable_module && var.db_subnetgroup_enable ? 1 : 0
  name       = var.db_subnet_group_name
  subnet_ids = aws_subnet.isolated.*.id
  tags       = var.tags
}


########################################
##  VPC Flowlogs configuration 
########################################
resource "random_id" "this" {
  count       = var.enable_module ? 1 : 0
  byte_length = 6
}

resource "aws_flow_log" "flowlogs" {
  count           = var.enable_module && var.vpc_flowlogs_enable ? 1 : 0
  iam_role_arn    = aws_iam_role.flowlogs[count.index].arn
  log_destination = aws_cloudwatch_log_group.flowlogs[count.index].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc[0].id
}

resource "aws_cloudwatch_log_group" "flowlogs" {
  count             = var.enable_module && var.vpc_flowlogs_enable ? 1 : 0
  name              = "${var.vpc_flowlogs_name}-${random_id.this[count.index].hex}"
  retention_in_days = 60
}

data "aws_iam_policy_document" "flowlogs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flowlogs" {
  count              = var.enable_module && var.vpc_flowlogs_enable ? 1 : 0
  name               = "${var.environment}-${var.vpc_name_prefix}-flowlogs-${random_id.this[count.index].hex}"
  assume_role_policy = data.aws_iam_policy_document.flowlogs_assume_role.json
}

data "aws_iam_policy_document" "flowlogs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flowlogs" {
  count  = var.enable_module && var.vpc_flowlogs_enable ? 1 : 0
  name   = "${var.environment}-${var.vpc_name_prefix}-flowlogs-${random_id.this[count.index].hex}"
  role   = aws_iam_role.flowlogs[count.index].id
  policy = data.aws_iam_policy_document.flowlogs.json
}