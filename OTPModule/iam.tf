## File: iam.tf
##==================================
## IAM Roles and Policies for Lambda
##==================================
resource "aws_iam_role" "lambda_role" {
  count = var.enable_module ? 1 : 0
  name  = "${var.lambda_role_name}-${random_id.this[0].hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}


# IAM Policies from files
locals {

  # allow lambda to write dynamodb table on both regions when multi-region replication in enabled
  dynamodb_table_permission = var.enable_module && var.enable_multi_region ? [ 
                "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.dynamodb_table_name}",
                "arn:aws:dynamodb:${var.secondary_region}:${local.account_id}:table/${var.dynamodb_table_name}"
            ] : [ "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.dynamodb_table_name}" ]

  # Dynamic values for template substitution
  template_vars = var.enable_module ? {
    account_id       = local.account_id
    enable_multi_region = var.enable_multi_region
    region           = var.region
    secondary_region = var.secondary_region
    table_name       = var.dynamodb_table_name
    kms_key_id       = aws_kms_key.primary_key[0].id
  } : {}

  # Get all JSON policy files
  policies = var.enable_module ? fileset("${path.module}/templates/policies", "*.json") : []
}

resource "aws_iam_policy" "lambda_policies" {
  for_each = var.enable_module ? toset(local.policies) : []

  name = "${replace(each.key, ".json", "")}-${random_id.this[0].hex}"

  # Use templatefile to substitute variables in JSON files
  # policy   = file("${path.module}/templates/policies/${each.key}")
  policy = templatefile("${path.module}/templates/policies/${each.key}", local.template_vars)

  # tags = var.tags
  tags = merge(var.tags, {
    PolicyFile = each.key
    Module     = "OTP"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  for_each = var.enable_module ? aws_iam_policy.lambda_policies : {}

  policy_arn = each.value.arn
  role       = aws_iam_role.lambda_role[0].name
}


##===============================================
## IAM Roles and Policies for APIgateway (Global)
##===============================================

# Single IAM Role for API Gateway CloudWatch Logs (Global - used by all regions)
resource "aws_iam_role" "apigw_cw_role" {
  count = var.enable_module ? 1 : 0
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

# Attach CloudWatch Logs policy to the role
resource "aws_iam_role_policy_attachment" "apigw_cw_policy" {
  count = var.enable_module ? 1 : 0  
  role       = aws_iam_role.apigw_cw_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

##========================================
## API Gateway Account Settings (Regional)
##========================================

# API Gateway Account settings - Primary Region
resource "aws_api_gateway_account" "apigw_cw_account" {
  count = var.enable_module ? 1 : 0  
  cloudwatch_role_arn = aws_iam_role.apigw_cw_role[0].arn
}

# API Gateway Account settings - Replica Region
resource "aws_api_gateway_account" "apigw_cw_account_replica" {
  count               = var.enable_module && var.enable_multi_region ? 1 : 0
  provider            = aws.replica
  cloudwatch_role_arn = aws_iam_role.apigw_cw_role[0].arn
}