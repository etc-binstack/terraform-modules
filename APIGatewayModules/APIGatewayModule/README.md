# AWS API Gateway Module

This Terraform module deploys a reusable AWS API Gateway REST API with comprehensive features for integration, security, and monitoring. It supports a Swagger/OpenAPI template for API definitions and includes toggles for enabling/disabling features like custom domains, IP whitelisting, Cognito, SQS, caching, WAF, and more.

## Features
- **Conditional Deployment**: Enable/disable the module with `enable_module`.
- **Endpoint Types**: Supports regional, edge, or private endpoints.
- **Integrations**: VPC Link (NLB), Cognito authorization, SQS queue integration.
- **Custom Domains**: Configures Route53 alias records with optional mutual TLS.
- **Security**: IP whitelisting, WAF association, API keys with usage plans.
- **Monitoring**: CloudWatch logging, metrics, and X-Ray tracing.
- **Caching**: Stage and method-level caching with encryption and authorization options.
- **Naming**: Dynamic naming with environment, prefix, and random suffix.
- **Tagging**: Consistent tagging across resources.
- **Validation**: Robust input validation for reliability.

## Requirements
- Terraform >= 1.0
- AWS Provider >= 5.0
- Random Provider >= 3.0

## Usage
The module uses a Swagger/OpenAPI template with placeholders for dynamic values. Example usage:

```hcl
module "api_gateway" {
  source               = "./path/to/module"
  enable_module        = true
  region               = "us-east-1"
  environment          = "dev"
  apigw_name_prefix    = "myapp"
  apigw_name           = "api"
  swagger_file_path    = "./swagger.json"
  nlb_uri              = "nlb.example.com"
  vpc_link_id          = "vpclink-123"
  tags                 = { Project = "MyProject" }
  enable_custom_domain = true
  apigw_subdomain      = "api"
  domain_name          = "example.com"
  acm_certificate_arn  = "arn:aws:acm:us-east-1:123:certificate/abc"
  public_dns_zone      = "Z123ABC"
  use_cognito_auth     = true
  cognito_arn          = "arn:aws:cognito-idp:us-east-1:123:userpool/us-east-1_abc"
  enable_api_key       = true
}
```

## Swagger Template Placeholders
The Swagger file must include these placeholders:
- `${api_title}`: API title (e.g., `${var.environment}-${var.apigw_name_prefix}-${var.apigw_name}`).
- `${nlb_uri}`: Network Load Balancer URI.
- `${vpc_link_id}`: VPC Link ID.
- `${api_custom_domain}`: Custom domain name (e.g., `${var.apigw_subdomain}.${var.domain_name}`).
- `${env}`: Environment (e.g., dev, prod).
- `${cognito_arn}`: Cognito User Pool ARN (if enabled).
- `${aws_account_id}`: AWS Account ID (for SQS).
- `${sqs_queue_name}`: SQS queue name.
- `${sqs_iam_role}`: IAM role ARN for SQS.
- `${aws_region}`: AWS region for SQS integration.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_module` | Whether to deploy the module | `bool` | `false` | no |
| `region` | AWS region for the deployment | `string` | `"us-east-1"` | no |
| `environment` | The environment (e.g., dev, prod, test) | `string` | n/a | yes |
| `apigw_name_prefix` | Prefix for API Gateway resource names | `string` | n/a | yes |
| `apigw_name` | Name of the API Gateway | `string` | n/a | yes |
| `apigw_stage_name` | Name of the API Gateway stage | `string` | `"prod"` | no |
| `swagger_file_path` | Path to the Swagger/OpenAPI template file | `string` | n/a | yes |
| `nlb_uri` | URI of the Network Load Balancer for VPC Link | `string` | n/a | yes |
| `vpc_link_id` | ID of the VPC Link | `string` | n/a | yes |
| `tags` | Map of tags to apply to resources | `map(string)` | `{}` | no |
| `random_suffix` | Optional random suffix for resource names | `string` | `""` | no |
| `description` | Description of the API Gateway | `string` | `""` | no |
| `binary_media_types` | List of binary media types supported by the API | `list(string)` | `[]` | no |
| `minimum_compression_size` | Minimum response size to compress (-1 to disable) | `number` | `-1` | no |
| `api_key_source` | Source of the API key (HEADER or AUTHORIZER) | `string` | `"HEADER"` | no |
| `disable_execute_api_endpoint` | Disable the default execute-api endpoint | `bool` | `false` | no |
| `enable_private_endpoint` | Enable private endpoint configuration | `bool` | `false` | no |
| `vpc_endpoint_ids` | List of VPC Endpoint IDs for private endpoint | `list(string)` | `[]` | no |
| `enable_custom_domain` | Enable custom domain name configuration | `bool` | `true` | no |
| `apigw_subdomain` | Subdomain for the custom domain | `string` | `""` | no |
| `domain_name` | Custom domain name | `string` | `""` | no |
| `acm_certificate_arn` | ARN of the ACM certificate for custom domain | `string` | `""` | no |
| `public_dns_zone` | Route53 public hosted zone ID | `string` | `""` | no |
| `enable_mutual_tls` | Enable mutual TLS for custom domain | `bool` | `false` | no |
| `truststore_uri` | S3 URI for truststore (PEM certificates) | `string` | `""` | no |
| `truststore_version` | Version of the truststore | `string` | `""` | no |
| `ip_white_list_enable` | Enable IP whitelisting | `bool` | `false` | no |
| `ip_whitelist` | List of IP addresses/CIDRs to whitelist | `list(string)` | `[]` | no |
| `use_cognito_auth` | Enable Cognito authorization | `bool` | `false` | no |
| `cognito_arn` | ARN of the Cognito User Pool | `string` | `""` | no |
| `integrate_sqs_queue` | Enable SQS integration | `bool` | `false` | no |
| `sqs_queue_name` | Name of the SQS queue | `string` | `""` | no |
| `aws_account_id` | AWS Account ID | `string` | `""` | no |
| `aws_region` | AWS region for SQS integration | `string` | `""` | no |
| `enable_client_certificate` | Enable client certificate for backend calls | `bool` | `true` | no |
| `stage_description` | Description for the stage | `string` | `""` | no |
| `stage_variables` | Map of stage variables | `map(string)` | `{}` | no |
| `enable_xray_tracing` | Enable X-Ray tracing | `bool` | `false` | no |
| `access_log_format` | Format for access logs | `string` | `"$context.requestId"` | no |
| `enable_cache_cluster` | Enable cache cluster for the stage | `bool` | `false` | no |
| `cache_cluster_size` | Size of the cache cluster | `string` | `"0.5"` | no |
| `enable_metrics` | Enable CloudWatch metrics | `bool` | `true` | no |
| `logging_level` | Logging level (OFF, ERROR, INFO) | `string` | `"ERROR"` | no |
| `enable_data_trace` | Enable full request/response logging | `bool` | `false` | no |
| `throttling_burst_limit` | Throttling burst limit | `number` | `5000` | no |
| `throttling_rate_limit` | Throttling rate limit | `number` | `10000` | no |
| `enable_caching` | Enable caching (requires enable_cache_cluster) | `bool` | `false` | no |
| `cache_ttl_in_seconds` | Cache TTL in seconds | `number` | `300` | no |
| `cache_data_encrypted` | Encrypt cache data | `bool` | `false` | no |
| `require_authorization_for_cache_control` | Require authorization for cache control | `bool` | `false` | no |
| `unauthorized_cache_control_header_strategy` | Strategy for unauthorized cache control headers | `string` | `"SUCCEED_WITH_RESPONSE_HEADER"` | no |
| `enable_waf` | Enable WAF association | `bool` | `false` | no |
| `waf_acl_arn` | ARN of the WAF Web ACL | `string` | `""` | no |
| `enable_api_key` | Enable API key and usage plan | `bool` | `false` | no |
| `api_key_name` | Name for the API key | `string` | `"default-apikey"` | no |
| `usage_plan_name` | Name for the usage plan | `string` | `"default-usageplan"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `api_id` | ID of the API Gateway REST API |
| `api_arn` | ARN of the API Gateway REST API |
| `invoke_url` | Invoke URL of the stage |
| `custom_domain` | Custom domain name |
| `api_key_value` | Value of the API key (sensitive) |

## Notes
- The Swagger template must include placeholders for dynamic values (see above).
- Caching requires both `enable_cache_cluster` and `enable_caching`; per-method caching can be defined in Swagger.
- Full logging (`enable_data_trace`) may incur additional costs.
- Ensure the AWS provider is configured with appropriate credentials.
- Validate configurations with `terraform validate` and `terraform plan`.

## Swagger Template Placeholders
The Swagger file (e.g., `swagger.json`) must include these placeholders:
- `${api_title}`: API title (e.g., `${var.environment}-${var.apigw_name_prefix}-${var.apigw_name}`).
- `${nlb_uri}`: Network Load Balancer URI for VPC Link integration.
- `${vpc_link_id}`: VPC Link ID.
- `${api_custom_domain}`: Custom domain name (e.g., `${var.apigw_subdomain}.${var.domain_name}` or empty if disabled).
- `${env}`: Environment (e.g., dev, prod).
- `${cognito_arn}`: Cognito User Pool ARN (empty if `use_cognito_auth` is false).
- `${aws_account_id}`: AWS Account ID for SQS (empty if `integrate_sqs_queue` is false).
- `${sqs_queue_name}`: SQS queue name (empty if `integrate_sqs_queue` is false).
- `${sqs_iam_role}`: IAM role ARN for SQS (empty if `integrate_sqs_queue` is false).
- `${aws_region}`: AWS region for SQS (empty if `integrate_sqs_queue` is false).
- `${enable_api_key}`: String "true" or "false" based on `enable_api_key`.

The template should handle conditional logic (e.g., `${sqs_queue_name != '' ? ... : ...}`) for integrations and security definitions for Cognito and API keys.


## Using the API Gateway Converter Script
The `aws-apigw-converter-latest.js` script converts a base `swagger.json` into an API Gateway-compatible specification for a given environment. It supports VPC Link, SQS, Cognito, and API key integrations.

### Prerequisites
- Node.js >= 12
- A valid `swagger.json` with paths, methods, and `operationId` values.

### Usage
1. Place `aws-apigw-converter-latest.js` and `swagger.json` in the same directory.
2. Run the script with an environment argument:
   ```bash
   node aws-apigw-converter-latest.js DEV
   ```
   Supported environments: `DEV`, `UAT`, `PROD`, `TF_VAR`.
3. For Terraform, use `TF_VAR` to preserve placeholders:
   ```bash
   node aws-apigw-converter-latest.js TF_VAR
   ```
4. The script generates `swagger-converted-<env>.json`. Use this file as `var.swagger_file_path` in the Terraform module:
   ```hcl
   module "api_gateway" {
     source            = "./path/to/module"
     swagger_file_path = "./swagger-converted-TF_VAR.json"
     ...
   }
   ```

### Notes
- Ensure `swagger.json` includes unique `operationId` values for each method.
- The script supports conditional logic for SQS (`${sqs_queue_name}`), Cognito (`${cognito_arn}`), and API keys (`${enable_api_key}`).
- For custom endpoints, modify `swagger.json` or provide a different input file.


## License
MIT
