## File: apigateway.tf
##============================
## API Gateway - Primary Region
##============================
resource "aws_api_gateway_rest_api" "otp_api" {
  count       = var.enable_module ? 1 : 0
  name        = "${var.api_gateway_name}-${random_id.this[0].hex}"
  description = "API Gateway for OTP service"

  tags = var.tags
}

# Base path for API
resource "aws_api_gateway_resource" "otp_base" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  parent_id   = aws_api_gateway_rest_api.otp_api[0].root_resource_id
  path_part   = "otp"
}

# Create Generate OTP resource and method
resource "aws_api_gateway_resource" "generate_otp" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  parent_id   = aws_api_gateway_resource.otp_base[0].id
  path_part   = "generate-otp"
}

resource "aws_api_gateway_method" "generate_otp" {
  count         = var.enable_module ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.otp_api[0].id
  resource_id   = aws_api_gateway_resource.generate_otp[0].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "generate_otp" {
  count                   = var.enable_module ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.otp_api[0].id
  resource_id             = aws_api_gateway_resource.generate_otp[0].id
  http_method             = aws_api_gateway_method.generate_otp[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.generate_otp[0].invoke_arn
  timeout_milliseconds    = 29000
  content_handling        = "CONVERT_TO_TEXT"
}

# OPTIONS method for CORS support - Generate OTP
resource "aws_api_gateway_method" "generate_otp_options" {
  count         = var.enable_module ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.otp_api[0].id
  resource_id   = aws_api_gateway_resource.generate_otp[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "generate_otp_options" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  resource_id = aws_api_gateway_resource.generate_otp[0].id
  http_method = aws_api_gateway_method.generate_otp_options[0].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method_response" "generate_otp_options_200" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  resource_id = aws_api_gateway_resource.generate_otp[0].id
  http_method = aws_api_gateway_method.generate_otp_options[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "generate_otp_options_200" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  resource_id = aws_api_gateway_resource.generate_otp[0].id
  http_method = aws_api_gateway_method.generate_otp_options[0].http_method
  status_code = aws_api_gateway_method_response.generate_otp_options_200[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Create Verify OTP resource and method
resource "aws_api_gateway_resource" "verify_otp" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  parent_id   = aws_api_gateway_resource.otp_base[0].id
  path_part   = "verify-otp"
}

resource "aws_api_gateway_method" "verify_otp" {
  count         = var.enable_module ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.otp_api[0].id
  resource_id   = aws_api_gateway_resource.verify_otp[0].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "verify_otp" {
  count                   = var.enable_module ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.otp_api[0].id
  resource_id             = aws_api_gateway_resource.verify_otp[0].id
  http_method             = aws_api_gateway_method.verify_otp[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.verify_otp[0].invoke_arn
  timeout_milliseconds    = 29000
  content_handling        = "CONVERT_TO_TEXT"
}

# OPTIONS method for CORS support - Verify OTP
resource "aws_api_gateway_method" "verify_otp_options" {
  count         = var.enable_module ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.otp_api[0].id
  resource_id   = aws_api_gateway_resource.verify_otp[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "verify_otp_options" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  resource_id = aws_api_gateway_resource.verify_otp[0].id
  http_method = aws_api_gateway_method.verify_otp_options[0].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method_response" "verify_otp_options_200" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  resource_id = aws_api_gateway_resource.verify_otp[0].id
  http_method = aws_api_gateway_method.verify_otp_options[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "verify_otp_options_200" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id
  resource_id = aws_api_gateway_resource.verify_otp[0].id
  http_method = aws_api_gateway_method.verify_otp_options[0].http_method
  status_code = aws_api_gateway_method_response.verify_otp_options_200[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "generate_otp" {
  count         = var.enable_module ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_otp[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.otp_api[0].execution_arn}/*/${aws_api_gateway_method.generate_otp[0].http_method}${aws_api_gateway_resource.generate_otp[0].path}"
}

resource "aws_lambda_permission" "verify_otp" {
  count         = var.enable_module ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_otp[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.otp_api[0].execution_arn}/*/${aws_api_gateway_method.verify_otp[0].http_method}${aws_api_gateway_resource.verify_otp[0].path}"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "otp_api" {
  count = var.enable_module ? 1 : 0
  depends_on = [
    aws_api_gateway_integration.generate_otp,
    aws_api_gateway_integration.verify_otp,
    aws_api_gateway_integration.generate_otp_options,
    aws_api_gateway_integration.verify_otp_options
  ]

  rest_api_id = aws_api_gateway_rest_api.otp_api[0].id

  lifecycle {
    create_before_destroy = true
  }
}

# Instead of using deprecated stage_name parameter, create a separate stage resource
resource "aws_api_gateway_stage" "otp_api" {
  count = var.enable_module ? 1 : 0

  deployment_id = aws_api_gateway_deployment.otp_api[0].id
  rest_api_id   = aws_api_gateway_rest_api.otp_api[0].id
  stage_name    = "v1"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs[0].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.tags
}

# CloudWatch Log Group for API Gateway Access Logs
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  count             = var.enable_module ? 1 : 0
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.otp_api[0].name}"
  retention_in_days = 30

  tags = var.tags
}

##============================
## API Gateway - Replica Region (if multi-region is enabled)
##============================
resource "aws_api_gateway_rest_api" "otp_api_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  name        = "${var.api_gateway_name}-${random_id.this[0].hex}"
  description = "API Gateway for OTP service (Replica Region)"

  tags = var.tags
}

# Base path for API in replica region
resource "aws_api_gateway_resource" "otp_base_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  parent_id   = aws_api_gateway_rest_api.otp_api_replica[0].root_resource_id
  path_part   = "otp"
}

# Create Generate OTP resource and method in replica region
resource "aws_api_gateway_resource" "generate_otp_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  parent_id   = aws_api_gateway_resource.otp_base_replica[0].id
  path_part   = "generate-otp"
}

resource "aws_api_gateway_method" "generate_otp_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  rest_api_id   = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id   = aws_api_gateway_resource.generate_otp_replica[0].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "generate_otp_replica" {
  count                   = var.enable_module && var.enable_multi_region ? 1 : 0
  provider                = aws.replica
  rest_api_id             = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id             = aws_api_gateway_resource.generate_otp_replica[0].id
  http_method             = aws_api_gateway_method.generate_otp_replica[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.generate_otp_replica[0].invoke_arn
  timeout_milliseconds    = 29000
  content_handling        = "CONVERT_TO_TEXT"
}

# OPTIONS method for CORS support - Generate OTP (Replica)
resource "aws_api_gateway_method" "generate_otp_options_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  rest_api_id   = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id   = aws_api_gateway_resource.generate_otp_replica[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "generate_otp_options_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id = aws_api_gateway_resource.generate_otp_replica[0].id
  http_method = aws_api_gateway_method.generate_otp_options_replica[0].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method_response" "generate_otp_options_200_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id = aws_api_gateway_resource.generate_otp_replica[0].id
  http_method = aws_api_gateway_method.generate_otp_options_replica[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "generate_otp_options_200_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id = aws_api_gateway_resource.generate_otp_replica[0].id
  http_method = aws_api_gateway_method.generate_otp_options_replica[0].http_method
  status_code = aws_api_gateway_method_response.generate_otp_options_200_replica[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Create Verify OTP resource and method in replica region
resource "aws_api_gateway_resource" "verify_otp_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  parent_id   = aws_api_gateway_resource.otp_base_replica[0].id
  path_part   = "verify-otp"
}

resource "aws_api_gateway_method" "verify_otp_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  rest_api_id   = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id   = aws_api_gateway_resource.verify_otp_replica[0].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "verify_otp_replica" {
  count                   = var.enable_module && var.enable_multi_region ? 1 : 0
  provider                = aws.replica
  rest_api_id             = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id             = aws_api_gateway_resource.verify_otp_replica[0].id
  http_method             = aws_api_gateway_method.verify_otp_replica[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.verify_otp_replica[0].invoke_arn
  timeout_milliseconds    = 29000
  content_handling        = "CONVERT_TO_TEXT"
}

# OPTIONS method for CORS support - Verify OTP (Replica)
resource "aws_api_gateway_method" "verify_otp_options_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  rest_api_id   = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id   = aws_api_gateway_resource.verify_otp_replica[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "verify_otp_options_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id = aws_api_gateway_resource.verify_otp_replica[0].id
  http_method = aws_api_gateway_method.verify_otp_options_replica[0].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_method_response" "verify_otp_options_200_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id = aws_api_gateway_resource.verify_otp_replica[0].id
  http_method = aws_api_gateway_method.verify_otp_options_replica[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "verify_otp_options_200_replica" {
  count       = var.enable_module && var.enable_multi_region ? 1 : 0
  provider    = aws.replica
  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id
  resource_id = aws_api_gateway_resource.verify_otp_replica[0].id
  http_method = aws_api_gateway_method.verify_otp_options_replica[0].http_method
  status_code = aws_api_gateway_method_response.verify_otp_options_200_replica[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda permissions for API Gateway in replica region
resource "aws_lambda_permission" "generate_otp_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_otp_replica[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.otp_api_replica[0].execution_arn}/*/${aws_api_gateway_method.generate_otp_replica[0].http_method}${aws_api_gateway_resource.generate_otp_replica[0].path}"
}

resource "aws_lambda_permission" "verify_otp_replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_otp_replica[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.otp_api_replica[0].execution_arn}/*/${aws_api_gateway_method.verify_otp_replica[0].http_method}${aws_api_gateway_resource.verify_otp_replica[0].path}"
}

# API Gateway deployment for replica region
resource "aws_api_gateway_deployment" "otp_api_replica" {
  count    = var.enable_module && var.enable_multi_region ? 1 : 0
  provider = aws.replica
  depends_on = [
    aws_api_gateway_integration.generate_otp_replica,
    aws_api_gateway_integration.verify_otp_replica,
    aws_api_gateway_integration.generate_otp_options_replica,
    aws_api_gateway_integration.verify_otp_options_replica
  ]

  rest_api_id = aws_api_gateway_rest_api.otp_api_replica[0].id

  lifecycle {
    create_before_destroy = true
  }
}

# Stage for replica region
resource "aws_api_gateway_stage" "otp_api_replica" {
  count    = var.enable_module && var.enable_multi_region ? 1 : 0
  provider = aws.replica

  deployment_id = aws_api_gateway_deployment.otp_api_replica[0].id
  rest_api_id   = aws_api_gateway_rest_api.otp_api_replica[0].id
  stage_name    = "v1"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs_replica[0].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.tags
}

# CloudWatch Log Group for API Gateway Access Logs in replica region
resource "aws_cloudwatch_log_group" "api_gateway_logs_replica" {
  count             = var.enable_module && var.enable_multi_region ? 1 : 0
  provider          = aws.replica
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.otp_api_replica[0].name}"
  retention_in_days = 30

  tags = var.tags
}