locals {
  # Determine which internet gateway to use
  internet_gateway_id = var.enable_module ? (
    var.internet_gateway_id != null ? var.internet_gateway_id :
    var.internet_gateway_name_tag != null ? try(data.aws_internet_gateway.by_name[0].id, null) :
    try(data.aws_internet_gateway.by_id[0].id, null)
  ) : null

  # NAT Gateway IDs
  nat_gateway_ids = var.enable_module && var.lookup_nat_gateways ? try(data.aws_nat_gateways.this[0].ids, []) : []

  # Common tags
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "vpc-existing"
    },
    var.additional_tags
  )

  # Subnet availability zones
  public_subnet_azs = var.enable_module ? [
    for subnet in data.aws_subnet.public : subnet.availability_zone
  ] : []

  private_subnet_azs = var.enable_module ? [
    for subnet in data.aws_subnet.private : subnet.availability_zone
  ] : []

  isolated_subnet_azs = var.enable_module ? [
    for subnet in data.aws_subnet.isolated : subnet.availability_zone
  ] : []

  # Count of subnets per type
  public_subnet_count   = var.public_subnet_ids != null ? length(var.public_subnet_ids) : 0
  private_subnet_count  = var.private_subnet_ids != null ? length(var.private_subnet_ids) : 0
  isolated_subnet_count = var.isolated_subnet_ids != null ? length(var.isolated_subnet_ids) : 0  
}
