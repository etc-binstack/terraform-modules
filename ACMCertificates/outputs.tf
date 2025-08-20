output "acm_certificate_id" {
  description = "The ID of the ACM certificate"
  value       = var.enable_module ? aws_acm_certificate.certs[0].id : null
}

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = var.enable_module ? aws_acm_certificate.certs[0].arn : null
}

output "acm_validation_status" {
  description = "The validation status of the ACM certificate"
  value       = var.enable_module && var.route53_validation && length(aws_acm_certificate_validation.certs) > 0 ? aws_acm_certificate_validation.certs[0].validation_status : "Not Validated"
}