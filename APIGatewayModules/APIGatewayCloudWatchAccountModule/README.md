# API Gateway CloudWatch Logging Module

This Terraform module configures an AWS API Gateway account with CloudWatch logging capabilities, including an IAM role and policy for logging. It is designed to be reusable across different environments (e.g., dev, prod, test) with customizable toggles for enabling/disabling features.

## Features
- Enables or disables the entire module using a toggle (`enable_module`).
- Configures an IAM role and policy for API Gateway to write logs to CloudWatch.
- Supports enabling/disabling CloudWatch logging specifically (`enable_cloudwatch_logging`).
- Generates a random ID for unique resource naming.
- Applies custom tags to resources for better organization.
- Supports multiple AWS regions.
- Includes input validation for environment and name prefix.

## Requirements
- Terraform >= 1.0
- AWS provider >= 4.0
- Random provider >= 3.0

## Usage
```hcl
module "apigw_cloudwatch" {
  source               = "./path/to/module"
  enable_module        = true
  environment          = "dev"
  name_prefix          = "myapp"
  enable_cloudwatch_logging = true
  region               = "us-west-2"
  tags = {
    Project = "MyProject"
    Owner   = "TeamA"
  }
}
```

## Inputs
| Name                   | Description                                      | Type          | Default       | Required |
|------------------------|--------------------------------------------------|---------------|---------------|----------|
| `enable_module`        | Whether to deploy the module or not              | `bool`        | `false`       | No       |
| `environment`          | The environment (dev, prod, test, staging)       | `string`      | None          | Yes      |
| `name_prefix`          | Prefix for resource names                        | `string`      | None          | Yes      |
| `enable_cloudwatch_logging` | Enable CloudWatch logging for API Gateway   | `bool`        | `true`        | No       |
| `tags`                 | Map of tags to apply to resources                | `map(string)` | `{}`          | No       |
| `region`               | AWS region for resource deployment               | `string`      | `us-east-1`   | No       |

## Outputs
None currently defined.

## Notes
- Ensure the AWS provider is configured with appropriate credentials.
- The `environment` variable is validated to accept only `dev`, `prod`, `test`, or `staging`.
- The `name_prefix` must be non-empty and up to 50 characters.
- The random ID ensures unique resource names to avoid conflicts.

## Example
```hcl
module "apigw_cloudwatch_prod" {
  source               = "./path/to/module"
  enable_module        = true
  environment          = "prod"
  name_prefix          = "app"
  enable_cloudwatch_logging = true
  region               = "us-east-1"
  tags = {
    Environment = "Production"
    CostCenter  = "12345"
  }
}
```

## License
MIT