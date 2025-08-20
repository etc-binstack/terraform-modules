#########################################
### Creat api gateway [Regional REST Api]
#########################################
provider "aws" {
  region = var.region
}

resource "random_id" "this" {
  count       = var.enable_module ? 1 : 0
  byte_length = 3 // ${random_id.this[count.index].hex}
}

## Define a local variable to conditionally choose random ID or the provided value
locals {
  random_id = var.random_suffix != "" ? var.random_suffix : (var.enable_module ? random_id.this[0].hex : "")
  effective_aws_region = var.aws_region != "" ? var.aws_region : var.region
}

## Create API Gateway
## ${path.module}/templates/src/${var.swagger_file_name}
resource "aws_api_gateway_rest_api" "apigw" {
  count = var.enable_module ? 1 : 0

  name                        = "${var.environment}-${var.apigw_name_prefix}-${var.apigw_name}"
  description                 = var.description
  body                        = templatefile(var.swagger_file_path, {
    api_title         = "${var.environment}-${var.apigw_name_prefix}-${var.apigw_name}"
    nlb_uri           = var.nlb_uri
    vpc_link_id       = var.vpc_link_id
    api_custom_domain = var.enable_custom_domain ? "${var.apigw_subdomain}.${var.domain_name}" : ""
    env               = var.environment
    cognito_arn       = var.use_cognito_auth ? var.cognito_arn : ""
    aws_account_id    = var.integrate_sqs_queue ? var.aws_account_id : ""
    sqs_queue_name    = var.integrate_sqs_queue ? var.sqs_queue_name : ""
    sqs_iam_role      = var.integrate_sqs_queue ? aws_iam_role.sqs_role[0].arn : ""
    aws_region        = var.integrate_sqs_queue ? local.effective_aws_region : ""
  })
  binary_media_types          = var.binary_media_types
  minimum_compression_size    = var.minimum_compression_size
  api_key_source              = var.api_key_source
  disable_execute_api_endpoint = var.disable_execute_api_endpoint

  endpoint_configuration {
    types            = var.enable_private_endpoint ? ["PRIVATE"] : ["REGIONAL"]
    vpc_endpoint_ids = var.enable_private_endpoint ? var.vpc_endpoint_ids : null
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [body]
  }
}

## Deploy json body to the api gateway
resource "aws_api_gateway_deployment" "apigw" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.apigw[0].id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.apigw[0].body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

## Add api-gateway client certificate
resource "aws_api_gateway_client_certificate" "apigw" {
  count       = var.enable_module && var.enable_client_certificate ? 1 : 0
  description = "${var.environment}-${var.apigw_name}-client-cert"
  tags        = var.tags
}

## Create a deployment stage (e.g. uat/pro/dev)
resource "aws_api_gateway_stage" "apigw" {
  count                 = var.enable_module ? 1 : 0
  deployment_id         = aws_api_gateway_deployment.apigw[0].id
  rest_api_id           = aws_api_gateway_rest_api.apigw[0].id
  stage_name            = var.apigw_stage_name
  description           = var.stage_description
  variables             = var.stage_variables
  client_certificate_id = var.enable_client_certificate ? aws_api_gateway_client_certificate.apigw[0].id : null
  cache_cluster_enabled = var.enable_cache_cluster
  cache_cluster_size    = var.enable_cache_cluster ? var.cache_cluster_size : null
  xray_tracing_enabled  = var.enable_xray_tracing

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw[0].arn
    format          = var.access_log_format
  }

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.apigw, aws_api_gateway_rest_api_policy.apigw]

  lifecycle {
    ignore_changes = [deployment_id]
  }
}

#########################################################
### Create a CloudWatch LOG group for API gateways metrix
#########################################################
# Create a API gateway cloudwatch logs for stage (e.g. uat/pro/dev)
resource "aws_api_gateway_method_settings" "apigw" {
  count       = var.enable_module ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.apigw[0].id
  stage_name  = aws_api_gateway_stage.apigw[0].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled                            = var.enable_metrics
    logging_level                              = var.logging_level
    data_trace_enabled                         = var.enable_data_trace
    throttling_burst_limit                     = var.throttling_burst_limit
    throttling_rate_limit                      = var.throttling_rate_limit
    caching_enabled                            = var.enable_caching && var.enable_cache_cluster
    cache_ttl_in_seconds                       = var.cache_ttl_in_seconds
    cache_data_encrypted                       = var.cache_data_encrypted
    require_authorization_for_cache_control    = var.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = var.unauthorized_cache_control_header_strategy
  }

  depends_on = [aws_api_gateway_stage.apigw]
}

resource "aws_cloudwatch_log_group" "apigw" {
  count             = var.enable_module ? 1 : 0
  name              = "/aws/apigateway/${var.environment}-${var.apigw_name_prefix}-${var.apigw_name}"
  retention_in_days = 30
  tags              = var.tags
}


###################################
## API Gateway [CUSTOM DOMAIN NAME]
###################################
## create domain name
resource "aws_api_gateway_domain_name" "apigw" {
  count                    = var.enable_module && var.enable_custom_domain ? 1 : 0
  domain_name              = "${var.apigw_subdomain}.${var.domain_name}"
  regional_certificate_arn = var.acm_certificate_arn
  security_policy          = "TLS_1_2"

  dynamic "mutual_tls_authentication" {
    for_each = var.enable_mutual_tls ? [1] : []
    content {
      truststore_uri     = var.truststore_uri
      truststore_version = var.truststore_version != "" ? var.truststore_version : null
    }
  }

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

## AWS API gateway STAGE base_PATH mapping with custom domain name
resource "aws_api_gateway_base_path_mapping" "apigw" {
  count       = var.enable_module && var.enable_custom_domain ? 1 : 0
  api_id      = aws_api_gateway_rest_api.apigw[0].id
  stage_name  = aws_api_gateway_stage.apigw[0].stage_name
  domain_name = aws_api_gateway_domain_name.apigw[0].domain_name
}

###############################################################
## Add api-gateway custom domain name record to Route53 service
###############################################################
# apigw DNS record using Route53.
resource "aws_route53_record" "apigw" {
  count   = var.enable_module && var.enable_custom_domain ? 1 : 0
  name    = aws_api_gateway_domain_name.apigw[0].domain_name
  type    = "A"
  zone_id = var.public_dns_zone

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.apigw[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.apigw[0].regional_zone_id
  }
}


###############################################################
## IP restriction: api-gateway 
###############################################################
data "aws_iam_policy_document" "apigw" {
  count = var.enable_module && var.ip_white_list_enable ? 1 : 0

  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["execute-api:Invoke"]
    resources = ["execute-api:/*/*/*"]
  }
  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["execute-api:Invoke"]
    resources = ["execute-api:/*/*/*"]
    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = var.ip_whitelist
    }
  }
}

## Deploy Resource Policy
resource "aws_api_gateway_rest_api_policy" "apigw" {
  count       = var.enable_module && var.ip_white_list_enable ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.apigw[0].id
  policy      = data.aws_iam_policy_document.apigw[0].json
  // depends_on  = [aws_api_gateway_rest_api.apigw]
}

resource "aws_wafv2_web_acl_association" "apigw" {
  count        = var.enable_module && var.enable_waf ? 1 : 0
  resource_arn = aws_api_gateway_stage.apigw[0].arn
  web_acl_arn  = var.waf_acl_arn
}

resource "aws_api_gateway_api_key" "apigw" {
  count = var.enable_module && var.enable_api_key ? 1 : 0
  name  = var.api_key_name
  tags  = var.tags
}

resource "aws_api_gateway_usage_plan" "apigw" {
  count = var.enable_module && var.enable_api_key ? 1 : 0
  name  = var.usage_plan_name

  api_stages {
    api_id = aws_api_gateway_rest_api.apigw[0].id
    stage  = aws_api_gateway_stage.apigw[0].stage_name
  }

  tags = var.tags
}

resource "aws_api_gateway_usage_plan_key" "apigw" {
  count         = var.enable_module && var.enable_api_key ? 1 : 0
  key_id        = aws_api_gateway_api_key.apigw[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.apigw[0].id
}