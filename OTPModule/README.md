# OTP Service Terraform Module

## Description

This Terraform module deploys a complete One-Time Password (OTP) service on AWS. It includes:

- AWS Lambda functions for generating and verifying OTPs (using Python 3.13 runtimes).
- Amazon DynamoDB table for storing OTP data with TTL and optional streaming.
- AWS KMS keys for encryption, with support for multi-region replication.
- AWS API Gateway REST API for exposing OTP generation and verification endpoints, including CORS support.
- IAM roles and policies for secure access.
- Optional multi-region (active/active DR) setup for high availability.
- CloudWatch logging for API Gateway.

The module is conditional on `enable_module` variable and supports single-region or multi-region deployments via `enable_multi_region`. All resources are tagged for organization.

**Note:** Lambda function code is sourced from zipped archives in the `templates/lambda/` directory (assumed to be pre-built and working). Policies are templated from JSON files in `templates/policies/`. KMS policies are from TPL files in `templates/kms/`.

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0
- Python 3.x (for Lambda code, if modifying)
- Access to AWS services: Lambda, DynamoDB, KMS, API Gateway, IAM, CloudWatch.

No external dependencies beyond AWS. Ensure you have AWS credentials configured.

## Directory Structure

The module follows a standard Terraform structure with separate files for resource categories. Here's the full directory layout:

```
OTPModule/
├── apigateway.tf               # API Gateway resources (primary and replica regions)
├── dynamodb.tf                 # DynamoDB table configuration
├── iam.tf                      # IAM roles, policies, and API Gateway account settings
├── kms.tf                      # KMS keys and policies (primary and replica)
├── lambda.tf                   # Lambda functions (generate/verify OTP, primary and replica)
├── otp.tf                      # Common resources (random ID, AWS provider alias)
├── outputs.tf                  # Module outputs
├── vars.tf                     # Input variables
├── templates/                  # Template files for policies, KMS, and Lambda code
│   ├── kms/                    # KMS policy templates
│   │   ├── mrk_policy.json.tpl # Multi-region KMS policy template
│   │   └── policy.json.tpl     # Single-region KMS policy template
│   ├── lambda/                 # Lambda function source code and zips (assumed working)
│   │   ├── generate_otp.py     # Python code for generate OTP Lambda
│   │   ├── verify_otp.py       # Python code for verify OTP Lambda
│   │   ├── generate_otp.zip    # Zipped archive for generate OTP Lambda
│   │   └── verify_otp.zip      # Zipped archive for verify OTP Lambda
│   └── policies/               # IAM policy JSON templates (dynamic, e.g., for DynamoDB, KMS, etc.)
│       ├── dynamodb.json       # Example: Policy for DynamoDB access (actual files depend on local.policies)
│       ├── kms.json            # Example: Policy for KMS access
│       └── logging.json        # Example: Policy for CloudWatch logging
└── README.md                   # This file: Documentation for the module
```

**Notes on Directory:**
- `templates/policies/*.json`: These are IAM policy files that are dynamically loaded and templated with variables like account ID, regions, etc.
- Lambda zips: Pre-built from `.py` files using `data "archive_file"`. If modifying code, re-zip manually or via CI/CD.
- No `main.tf` in the module root; resources are split across `.tf` files for modularity.

## Usage

To use this module, reference it in your root Terraform configuration (e.g., `main.tf`):

```hcl
module "otp_service" {
  source = "./path/to/OTPModule"  # Or Git URL for remote sourcing

  # Required variables
  enable_module            = true
  region                   = "us-east-1"
  secondary_region         = "us-west-2"
  lambda_role_name         = "otp-lambda-role"
  sendgrid_api_key         = "your-sendgrid-api-key"  # Sensitive
  email_sender             = "otp@example.com"
  lambda_generate_otp_name = "generate-otp-func"
  lambda_verify_otp_name   = "verify-otp-func"
  kms_key_alias            = "otp-kms-key"
  dynamodb_table_name      = "otp-table"
  api_gateway_name         = "otp-api"

  # Optional variables
  enable_multi_region      = true  # Enable DR setup
  enable_key_rotation      = true
  enable_dynamodb_stream   = false
  dynamodb_stream_view_type = "NEW_AND_OLD_IMAGES"
  deletion_protection      = false
  tags = {
    Environment = "prod"
    Project     = "otp-service"
  }
}

# Example outputs usage
output "primary_api_url" {
  value = module.otp_service.primary_api_gateway_url
}
```
## For .tfvars with multiple environemnts.
```hcl
# Data source to get current AWS caller identity
data "aws_caller_identity" "current" {}

# OTP Module
module "otp_service" {
  source = "../../AWSModules/OTPModule"

  # Module enablement
  enable_module = var.module_flags["enable_otp_module"]

  # Account and regions
  region           = var.primary_region
  secondary_region = var.secondary_region

  # IAM configuration
  lambda_role_name = "${var.environment}-${var.project}-${var.lambda_role_name}"

  # Lambda configuration
  sendgrid_api_key         = var.sendgrid_api_key
  email_sender             = var.email_sender
  lambda_generate_otp_name = "${var.environment}-${var.project}-${var.lambda_generate_otp_name}"
  lambda_verify_otp_name   = "${var.environment}-${var.project}-${var.lambda_verify_otp_name}"

  # KMS configuration
  kms_key_alias       = "${var.environment}-${var.project}-${var.kms_key_alias}"
  enable_multi_region = var.enable_multi_region
  enable_key_rotation = var.enable_key_rotation

  # DynamoDB configuration
  dynamodb_table_name = "${var.environment}-${var.project}-${var.dynamodb_table_name}"
  deletion_protection = var.deletion_protection

  # API Gateway configuration
  api_gateway_name = "${var.environment}-${var.project}-${var.api_gateway_name}"

  # Tags
  tags = merge(
    local.common_tags,
    {
      Application = "OTP-Service"
    }
  )
}

# Outputs
output "lambda_generate_otp_function_name" {
  description = "Name of the generate OTP Lambda function"
  value       = module.otp_service.lambda_generate_otp_function_name
}

output "lambda_verify_otp_function_name" {
  description = "Name of the verify OTP Lambda function"
  value       = module.otp_service.lambda_verify_otp_function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.otp_service.dynamodb_table_name
}

output "kms_primary_key_arn" {
  description = "ARN of the primary KMS key"
  value       = module.otp_service.kms_primary_key_arn
}

output "kms_replica_key_arn" {
  description = "ARN of the replica KMS key"
  value       = module.otp_service.kms_replica_key_arn
}

output "primary_api_gateway_url" {
  description = "URL of the primary API Gateway"
  value       = module.otp_service.primary_api_gateway_url
}

output "replica_api_gateway_url" {
  description = "URL of the replica API Gateway"
  value       = module.otp_service.replica_api_gateway_url
}
```

After defining the module, run:
- `terraform init`
- `terraform plan`
- `terraform apply`

**Endpoints (after deployment):**
- Generate OTP: `POST /otp/generate-otp` (body: e.g., `{ "user_id": "user123", "email": "user@example.com" }`)
- Verify OTP: `POST /otp/verify-otp` (body: e.g., `{ "user_id": "user123", "otp": "123456" }`)

The full invoke URL is output as `primary_api_gateway_url` (e.g., `https://abc123.execute-api.us-east-1.amazonaws.com/v1`).

For multi-region, use `replica_api_gateway_url` for the secondary region.

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `enable_module` | Toggle to enable/disable the entire module | `bool` | `false` | Yes |
| `tags` | Tags applied to all resources | `map(string)` | `{}` | No |
| `region` | Primary AWS region | `string` | N/A | Yes |
| `secondary_region` | Secondary AWS region for DR | `string` | N/A | Yes (if multi-region) |
| `lambda_role_name` | Name for Lambda IAM role | `string` | N/A | Yes |
| `sendgrid_api_key` | SendGrid API key for emails (sensitive) | `string` | N/A | Yes |
| `email_sender` | Sender email for OTP emails | `string` | N/A | Yes |
| `lambda_generate_otp_name` | Name for generate OTP Lambda | `string` | N/A | Yes |
| `lambda_verify_otp_name` | Name for verify OTP Lambda | `string` | N/A | Yes |
| `kms_key_alias` | Alias for KMS key | `string` | N/A | Yes |
| `enable_multi_region` | Enable multi-region DR | `bool` | `false` | No |
| `enable_key_rotation` | Enable KMS key rotation | `bool` | `true` | No |
| `dynamodb_table_name` | DynamoDB table name | `string` | N/A | Yes |
| `api_gateway_name` | API Gateway name | `string` | N/A | Yes |
| `enable_dynamodb_stream` | Enable DynamoDB streams (auto-enabled for multi-region) | `bool` | `false` | No |
| `dynamodb_stream_view_type` | Stream view type (e.g., "NEW_AND_OLD_IMAGES") | `string` | `"NEW_AND_OLD_IMAGES"` | No |
| `deletion_protection` | Enable deletion protection on DynamoDB | `bool` | `false` | No |

## Output Values

| Name | Description | Value |
|------|-------------|-------|
| `lambda_generate_otp_function_name` | Name of generate OTP Lambda | `aws_lambda_function.generate_otp.function_name` |
| `lambda_verify_otp_function_name` | Name of verify OTP Lambda | `aws_lambda_function.verify_otp.function_name` |
| `dynamodb_table_name` | DynamoDB table name | `aws_dynamodb_table.otp_table.name` |
| `kms_primary_key_arn` | ARN of primary KMS key | `aws_kms_key.primary_key.arn` |
| `kms_replica_key_arn` | ARN of replica KMS key (if multi-region) | `aws_kms_replica_key.replica_key.arn` |
| `primary_api_gateway_url` | Invoke URL for primary API Gateway | `aws_api_gateway_deployment.otp_api.invoke_url` |
| `replica_api_gateway_url` | Invoke URL for replica API Gateway (if multi-region) | `aws_api_gateway_deployment.otp_api_replica.invoke_url` |

## Notes

- **Multi-Region Setup:** When `enable_multi_region = true`, resources are replicated in the secondary region using an AWS provider alias. DynamoDB uses global tables, KMS uses multi-region keys.
- **Security:** KMS keys have custom policies allowing Lambda access. IAM policies are templated for DynamoDB/KMS/Logging.
- **Lambda Code:** Assumes `generate_otp.py` and `verify_otp.py` handle OTP logic (e.g., email via SendGrid/SES, encryption via KMS, storage in DynamoDB). Update and re-zip if needed.
- **Costs:** Pay-per-request billing for DynamoDB/Lambda/API Gateway. Enable deletion protection to avoid accidental deletes.
- **Limitations:** No automatic Lambda code zipping in module (uses pre-zipped files). Streams are required and auto-enabled for multi-region.
- **Troubleshooting:** Check CloudWatch logs for API/Lambda errors. Ensure SendGrid API key is valid for email delivery.
- **Further Use:** Extend by adding more endpoints or integrating with other services (e.g., SNS for SMS OTPs). For production, use Terraform workspaces or CI/CD for deployments.

For questions or contributions, contact the maintainer.


## License
This module is licensed under the MIT License. See the LICENSE file for details.
## Contributing
Contributions are welcome! Please submit issues or pull requests on the repository. Ensure your code adheres to the existing style and includes tests where applicable.