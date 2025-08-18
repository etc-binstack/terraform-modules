## Public Hosted Zone - Create New
resource "aws_route53_zone" "public" {
  count = var.enable_public_zone && !var.use_existing_public_zone ? 1 : 0
  name  = var.public_domain_name
  tags  = var.tags
}

## Public Hosted Zone - Fetch Existing
data "aws_route53_zone" "public" {
  count        = var.enable_public_zone && var.use_existing_public_zone && var.existing_public_zone_id != null ? 1 : 0
  zone_id      = var.existing_public_zone_id
  private_zone = false
}

## Private Hosted Zone - Create New
resource "aws_route53_zone" "private" {
  count = var.enable_private_zone && !var.use_existing_private_zone ? 1 : 0
  name  = var.private_domain_name
  vpc {
    vpc_id = var.vpc_id
  }
  tags = var.tags
}

## Private Hosted Zone Association (for existing zones)
resource "aws_route53_zone_association" "private" {
  count = var.enable_private_zone && var.use_existing_private_zone && var.existing_private_zone_id != null && var.vpc_id != null ? 1 : 0
  zone_id = var.existing_private_zone_id
  vpc_id  = var.vpc_id
}