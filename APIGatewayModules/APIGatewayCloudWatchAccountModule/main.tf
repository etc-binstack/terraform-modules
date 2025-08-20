# Generating a random ID for unique resource naming
resource "random_id" "this" {
  count       = var.enable_module ? 1 : 0
  byte_length = 3
}

# Configuring provider region
provider "aws" {
  region = var.region
}

# Setting up API Gateway CloudWatch account
resource "aws_api_gateway_account" "apigw" {
  count               = var.enable_module && var.enable_cloudwatch_logging ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigw[0].arn
}

# Creating IAM role for API Gateway CloudWatch logging
resource "aws_iam_role" "apigw" {
  count = var.enable_module && var.enable_cloudwatch_logging ? 1 : 0
  name  = "${var.environment}-${var.name_prefix}-apigw-logs-role-${random_id.this[0].hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Environment = var.environment
    },
    var.tags
  )
}

# Defining IAM role policy for CloudWatch logging permissions
resource "aws_iam_role_policy" "apigw" {
  count = var.enable_module && var.enable_cloudwatch_logging ? 1 : 0
  name  = "${var.environment}-${var.name_prefix}-apigw-policy"
  role  = aws_iam_role.apigw[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}