output "public_zone_id" {
  description = "The ID of the public Route 53 hosted zone (either created or fetched)"
  value       = var.enable_public_zone ? (var.use_existing_public_zone ? data.aws_route53_zone.public[0].zone_id : aws_route53_zone.public[0].id) : null
}

output "public_domain_name" {
  description = "The domain name of the public Route 53 hosted zone (either created or fetched)"
  value       = var.enable_public_zone ? (var.use_existing_public_zone ? data.aws_route53_zone.public[0].name : aws_route53_zone.public[0].name) : null
}

output "private_zone_id" {
  description = "The ID of the private Route 53 hosted zone (either created or associated)"
  value       = var.enable_private_zone ? (var.use_existing_private_zone ? aws_route53_zone_association.private[0].zone_id : aws_route53_zone.private[0].id) : null
}

output "private_domain_name" {
  description = "The domain name of the private Route 53 hosted zone (if created)"
  value       = var.enable_private_zone && !var.use_existing_private_zone ? aws_route53_zone.private[0].name : null
}