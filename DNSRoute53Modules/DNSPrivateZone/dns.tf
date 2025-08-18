resource "aws_route53_zone" "private" {

  count = var.enable_module ? 1 : 0
  name  = var.private_domain_name
  vpc {
    vpc_id = var.vpc_id
  }

  tags = var.tags

}