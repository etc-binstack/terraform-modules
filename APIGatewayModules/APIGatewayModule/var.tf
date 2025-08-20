## API Gateway
variable "enable_module" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}

variable "region" {
  description = "AWS region for the deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The environment (e.g., dev, prod, test)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "test", "staging"], var.environment)
    error_message = "Environment must be one of: dev, prod, test, staging"
  }
}

variable "apigw_name_prefix" {
  description = "Prefix for API Gateway resource names"
  type        = string
  validation {
    condition     = length(var.apigw_name_prefix) > 0
    error_message = "API Gateway name prefix must not be empty"
  }
}

variable "apigw_name" {
  description = "Name of the API Gateway"
  type        = string
  validation {
    condition     = length(var.apigw_name) > 0
    error_message = "API Gateway name must not be empty"
  }
}

variable "apigw_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "prod"
}

variable "swagger_file_path" {
  description = "Path to the Swagger/OpenAPI template file"
  type        = string
  validation {
    condition     = fileexists(var.swagger_file_path)
    error_message = "Swagger file path must point to an existing file"
  }
}

variable "nlb_uri" {
  description = "URI of the Network Load Balancer for VPC Link integration"
  type        = string
}

variable "vpc_link_id" {
  description = "ID of the VPC Link"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "random_suffix" {
  description = "Optional random suffix for resource names"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "binary_media_types" {
  description = "List of binary media types supported by the API"
  type        = list(string)
  default     = []
}

variable "minimum_compression_size" {
  description = "Minimum response size to compress (-1 to disable)"
  type        = number
  default     = -1
  validation {
    condition     = var.minimum_compression_size == -1 || (var.minimum_compression_size >= 0 && var.minimum_compression_size <= 10485760)
    error_message = "Minimum compression size must be -1 or between 0 and 10485760"
  }
}

variable "api_key_source" {
  description = "Source of the API key for requests (HEADER or AUTHORIZER)"
  type        = string
  default     = "HEADER"
  validation {
    condition     = contains(["HEADER", "AUTHORIZER"], var.api_key_source)
    error_message = "API key source must be HEADER or AUTHORIZER"
  }
}

variable "disable_execute_api_endpoint" {
  description = "Disable the default execute-api endpoint"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint configuration"
  type        = bool
  default     = false
}

variable "vpc_endpoint_ids" {
  description = "List of VPC Endpoint IDs for private endpoint"
  type        = list(string)
  default     = []
  validation {
    condition     = !var.enable_private_endpoint || length(var.vpc_endpoint_ids) > 0
    error_message = "VPC Endpoint IDs must be provided when enable_private_endpoint is true"
  }
}

variable "enable_custom_domain" {
  description = "Enable custom domain name configuration"
  type        = bool
  default     = true
}

variable "apigw_subdomain" {
  description = "Subdomain for the custom domain"
  type        = string
  default     = ""
  validation {
    condition     = !var.enable_custom_domain || length(var.apigw_subdomain) > 0
    error_message = "Subdomain must be provided when enable_custom_domain is true"
  }
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = ""
  validation {
    condition     = !var.enable_custom_domain || length(var.domain_name) > 0
    error_message = "Domain name must be provided when enable_custom_domain is true"
  }
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for custom domain"
  type        = string
  default     = ""
  validation {
    condition     = !var.enable_custom_domain || length(var.acm_certificate_arn) > 0
    error_message = "ACM certificate ARN must be provided when enable_custom_domain is true"
  }
}

variable "public_dns_zone" {
  description = "Route53 public hosted zone ID"
  type        = string
  default     = ""
  validation {
    condition     = !var.enable_custom_domain || length(var.public_dns_zone) > 0
    error_message = "Public DNS zone ID must be provided when enable_custom_domain is true"
  }
}

variable "enable_mutual_tls" {
  description = "Enable mutual TLS for custom domain"
  type        = bool
  default     = false
}

variable "truststore_uri" {
  description = "S3 URI for truststore (PEM certificates)"
  type        = string
  default     = ""
  validation {
    condition     = !var.enable_mutual_tls || startswith(var.truststore_uri, "s3://")
    error_message = "Truststore URI must be an S3 path when enable_mutual_tls is true"
  }
}

variable "truststore_version" {
  description = "Version of the truststore"
  type        = string
  default     = ""
}

variable "ip_white_list_enable" {
  description = "Enable IP whitelisting"
  type        = bool
  default     = false
}

variable "ip_whitelist" {
  description = "List of IP addresses/CIDRs to whitelist"
  type        = list(string)
  default     = []
  validation {
    condition     = !var.ip_white_list_enable || length(var.ip_whitelist) > 0
    error_message = "IP whitelist must not be empty when enabled"
  }
}

variable "use_cognito_auth" {
  description = "Enable Cognito authorization"
  type        = bool
  default     = false
}

variable "cognito_arn" {
  description = "ARN of the Cognito User Pool"
  type        = string
  default     = ""
  validation {
    condition     = !var.use_cognito_auth || length(var.cognito_arn) > 0
    error_message = "Cognito ARN must be provided when use_cognito_auth is true"
  }
}

variable "integrate_sqs_queue" {
  description = "Enable SQS integration"
  type        = bool
  default     = false
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = ""
  validation {
    condition     = !var.integrate_sqs_queue || length(var.sqs_queue_name) > 0
    error_message = "SQS queue name must be provided when integrate_sqs_queue is true"
  }
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
  validation {
    condition     = !var.integrate_sqs_queue || length(var.aws_account_id) > 0
    error_message = "AWS Account ID must be provided when integrate_sqs_queue is true"
  }
}

variable "aws_region" {
  description = "AWS region for SQS integration (defaults to module region)"
  type        = string
  default     = ""
}

variable "enable_client_certificate" {
  description = "Enable client certificate for backend calls"
  type        = bool
  default     = true
}

variable "stage_description" {
  description = "Description for the stage"
  type        = string
  default     = ""
}

variable "stage_variables" {
  description = "Map of stage variables"
  type        = map(string)
  default     = {}
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

variable "access_log_format" {
  description = "Format for access logs"
  type        = string
  default     = "$context.requestId"
}

variable "enable_cache_cluster" {
  description = "Enable cache cluster for the stage"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster"
  type        = string
  default     = "0.5"
  validation {
    condition     = contains(["0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237"], var.cache_cluster_size)
    error_message = "Invalid cache cluster size"
  }
}

variable "enable_metrics" {
  description = "Enable CloudWatch metrics"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Logging level (OFF, ERROR, INFO)"
  type        = string
  default     = "ERROR"
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.logging_level)
    error_message = "Logging level must be OFF, ERROR, or INFO"
  }
}

variable "enable_data_trace" {
  description = "Enable full request/response logging"
  type        = bool
  default     = false
}

variable "throttling_burst_limit" {
  description = "Throttling burst limit"
  type        = number
  default     = 5000
}

variable "throttling_rate_limit" {
  description = "Throttling rate limit"
  type        = number
  default     = 10000
}

variable "enable_caching" {
  description = "Enable caching (requires enable_cache_cluster)"
  type        = bool
  default     = false
}

variable "cache_ttl_in_seconds" {
  description = "Cache TTL in seconds"
  type        = number
  default     = 300
}

variable "cache_data_encrypted" {
  description = "Encrypt cache data"
  type        = bool
  default     = false
}

variable "require_authorization_for_cache_control" {
  description = "Require authorization for cache control"
  type        = bool
  default     = false
}

variable "unauthorized_cache_control_header_strategy" {
  description = "Strategy for unauthorized cache control headers"
  type        = string
  default     = "SUCCEED_WITH_RESPONSE_HEADER"
  validation {
    condition     = contains(["FAIL_WITH_403", "SUCCEED_WITH_RESPONSE_HEADER", "SUCCEED_WITHOUT_RESPONSE_HEADER"], var.unauthorized_cache_control_header_strategy)
    error_message = "Invalid unauthorized cache control strategy"
  }
}

variable "enable_waf" {
  description = "Enable WAF association"
  type        = bool
  default     = false
}

variable "waf_acl_arn" {
  description = "ARN of the WAF Web ACL"
  type        = string
  default     = ""
  validation {
    condition     = !var.enable_waf || length(var.waf_acl_arn) > 0
    error_message = "WAF ACL ARN must be provided when enable_waf is true"
  }
}

variable "enable_api_key" {
  description = "Enable API key and usage plan"
  type        = bool
  default     = false
}

variable "api_key_name" {
  description = "Name for the API key"
  type        = string
  default     = "default-apikey"
}

variable "usage_plan_name" {
  description = "Name for the usage plan"
  type        = string
  default     = "default-usageplan"
}