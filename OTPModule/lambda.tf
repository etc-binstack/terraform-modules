## File: lambda.tf
##============================
## Lambda Functions - Primary Region
##============================
# data "archive_file" "generate_otp_zip" {
#   count       = var.enable_module ? 1 : 0  
#   type        = "zip"
#   source_file = "${path.module}/templates/lambda/generate_otp.py"
#   output_path = "${path.module}/templates/lambda/generate_otp.zip"
# }

data "archive_file" "verify_otp_zip" {
  count       = var.enable_module ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/templates/lambda/verify_otp.py"
  output_path = "${path.module}/templates/lambda/verify_otp.zip"
}

resource "aws_lambda_function" "generate_otp" {
  count         = var.enable_module ? 1 : 0
  filename      = "${path.module}/templates/lambda/generate_otp.zip" //data.archive_file.generate_otp_zip[0].output_path
  function_name = "${var.lambda_generate_otp_name}-${random_id.this[0].hex}"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "generate_otp.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  environment {
    variables = {
      DYNAMODB_TABLE      = aws_dynamodb_table.otp_table[0].name
      KMS_KEY_ID          = aws_kms_key.primary_key[0].key_id
      SENDGRID_API_KEY    = var.sendgrid_api_key
      SENDGRID_FROM_EMAIL = var.email_sender
      SES_FROM_EMAIL      = var.email_sender
      OTP_EXPIRATION_TIME = 5
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "verify_otp" {
  count         = var.enable_module ? 1 : 0
  filename      = data.archive_file.verify_otp_zip[0].output_path
  function_name = "${var.lambda_verify_otp_name}-${random_id.this[0].hex}"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "verify_otp.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.otp_table[0].name
      KMS_KEY_ID     = aws_kms_key.primary_key[0].key_id
    }
  }

  tags = var.tags
}

##============================
## Lambda Functions - Replica Region
##============================
resource "aws_lambda_function" "generate_otp_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  filename      = "${path.module}/templates/lambda/generate_otp.zip" //data.archive_file.generate_otp_zip[0].output_path
  function_name = "${var.lambda_generate_otp_name}-${random_id.this[0].hex}"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "generate_otp.lambda_handler"
  runtime       = "python3.13"
  timeout       = 15

  environment {
    variables = {
      DYNAMODB_TABLE      = aws_dynamodb_table.otp_table[0].name
      KMS_KEY_ID          = aws_kms_replica_key.replica_key[0].key_id
      SENDGRID_API_KEY    = var.sendgrid_api_key
      SENDGRID_FROM_EMAIL = var.email_sender
      SES_FROM_EMAIL      = var.email_sender
      OTP_EXPIRATION_TIME = 5
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "verify_otp_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  filename      = data.archive_file.verify_otp_zip[0].output_path
  function_name = "${var.lambda_verify_otp_name}-${random_id.this[0].hex}"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "verify_otp.lambda_handler"
  runtime       = "python3.13"
  timeout       = 15

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.otp_table[0].name
      KMS_KEY_ID     = aws_kms_replica_key.replica_key[0].key_id
    }
  }

  tags = var.tags
}
