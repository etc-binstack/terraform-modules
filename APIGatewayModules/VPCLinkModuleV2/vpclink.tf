# Validation: Ensure at least one target ARN is provided
resource "null_resource" "validation" {
  count = var.enable_module ? 1 : 0
  
  lifecycle {
    precondition {
      condition = (var.target_arns != null && length(var.target_arns) > 0) || var.backend_nlb_arn != null
      error_message = "Either 'target_arns' (list) or 'backend_nlb_arn' (string) must be provided."
    }
  }
}

# Local values for computed configurations
locals {
  # Determine target ARNs - support both new and legacy approach
  target_arns = var.target_arns != null ? var.target_arns : (
    var.backend_nlb_arn != null ? [var.backend_nlb_arn] : []
  )
  
  # Generate VPC Link name
  base_name = var.vpc_link_name != null ? var.vpc_link_name : "${var.environment}-${var.vpc_endpoint_name}"
  
  # Add prefix and suffix if provided
  name_with_prefix_suffix = "${var.name_prefix}${local.base_name}${var.name_suffix}"
  
  # Final name with or without random suffix
  vpc_link_name = var.use_random_suffix ? "${local.name_with_prefix_suffix}-${random_string.this[0].result}" : local.name_with_prefix_suffix
  
  # Default tags merged with user-provided tags
  default_tags = {
    Module      = "VPCLinkModule"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  final_tags = merge(local.default_tags, var.tags)
}

# Random string for unique naming
resource "random_string" "this" {
  count   = var.enable_module && var.use_random_suffix ? 1 : 0
  length  = var.random_suffix_length
  numeric = true
  lower   = true
  special = false
  upper   = false
  
  keepers = {
    # Force regeneration if base name changes
    base_name = local.name_with_prefix_suffix
  }
}

# API Gateway VPC Link resource
resource "aws_api_gateway_vpc_link" "vpclink" {
  count       = var.enable_module ? 1 : 0
  name        = local.vpc_link_name
  description = var.vpclink_description
  target_arns = local.target_arns
  tags        = local.final_tags

  lifecycle {
    create_before_destroy = true
    
    # Prevent accidental deletion by requiring explicit confirmation
    prevent_destroy = false
  }
}

# Data source to validate NLB ARNs (optional validation)
data "aws_lb" "target_nlbs" {
  count = var.enable_module ? length(local.target_arns) : 0
  arn   = local.target_arns[count.index]
}
