## Public Hosted Zone
resource "aws_route53_zone" "public" {

  count = var.enable_module ? 1 : 0
  name  = var.domain_name
  tags  = var.tags
}