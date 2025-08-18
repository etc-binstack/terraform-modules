## Public Hosted Zone - fetching existing zone
data "aws_route53_zone" "public" {
  zone_id      = var.zone_id
  private_zone = false

  tags = var.tags
}