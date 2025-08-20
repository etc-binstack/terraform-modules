############################################
## AWS SQS: api-gateway IAM role / policy 
############################################
data "aws_iam_policy_document" "sqs_role" {
  count = var.enable_module && var.integrate_sqs_queue ? 1 : 0
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sqs_role" {
  count              = var.enable_module && var.integrate_sqs_queue ? 1 : 0
  name               = "${var.environment}-${var.apigw_name_prefix}-${var.apigw_name}-role-for-sqs-${local.random_id}"
  assume_role_policy = data.aws_iam_policy_document.sqs_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "sqs_policy" {
  count      = var.enable_module && var.integrate_sqs_queue ? 1 : 0
  role       = aws_iam_role.sqs_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "cwl_policy" {
  count      = var.enable_module && var.integrate_sqs_queue ? 1 : 0
  role       = aws_iam_role.sqs_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
