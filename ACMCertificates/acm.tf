## Generate wildcard certificate in ACM 
resource "aws_acm_certificate" "certs" {
  count                     = var.enable_module ? 1 : 0
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = var.enable_sans ? concat(["${var.domain_name}"], var.subject_alternative_names) : []
  validation_method         = var.route53_validation ? "DNS" : "NONE"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

## Validate ACM certificate using Route53 DNS
data "aws_route53_zone" "acm_domain" {
  count        = var.enable_module && var.route53_validation ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "certs" {
  for_each = var.enable_module && var.route53_validation && length(aws_acm_certificate.certs) > 0 ? {
    for dvo in aws_acm_certificate.certs[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.acm_domain[0].zone_id
}

resource "aws_acm_certificate_validation" "certs" {
  count                   = var.enable_module && var.route53_validation && length(aws_route53_record.certs) > 0 ? 1 : 0
  certificate_arn         = aws_acm_certificate.certs[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certs : record.fqdn]
}