## Private hosted zone
resource "aws_route53_zone_association" "private" {
  // count = var.enable_module ? 1 : 0
  count = (var.enable_module && var.zone_id != null && var.vpc_id != null)

  zone_id = var.zone_id
  vpc_id  = var.vpc_id
}