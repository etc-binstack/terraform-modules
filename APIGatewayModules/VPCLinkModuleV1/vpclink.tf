resource "random_string" "this" {
  count   = var.enable_module ? 1 : 0
  length  = 3 // ${random_string.this[count.index].result} added in - V2
  numeric = true
  lower   = true
  special = false
  upper   = false
}

resource "aws_api_gateway_vpc_link" "vpclink" {
  count       = var.enable_module ? 1 : 0
  name        = "${var.environment}-${var.vpc_endpoint_name}-${random_string.this[count.index].result}"
  description = var.vpclink_description
  target_arns = [var.backend_nlb_arn]
  tags        = var.tags
}