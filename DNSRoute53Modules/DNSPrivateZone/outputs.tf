output "private_zone_id" {
  value = var.enable_module ? aws_route53_zone.private[0].id : null
}

output "private_domain_name" {
  value = var.enable_module ? aws_route53_zone.private[0].name : null
}