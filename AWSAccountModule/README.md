# AWS Account Information Module

This Terraform module retrieves AWS account-related information, including account ID, caller identity, ELB service account, region, and partition details. It is designed to be reusable, configurable, and efficient, with toggle switches to enable or disable specific data retrievals. The module is split into `main.tf` for data sources and `outputs.tf` for output definitions, ensuring modularity and clarity.

## Features
- **AWS Caller Identity**: Retrieves account ID, caller ARN, and user ID using the `aws_caller_identity` data source.
- **ELB Service Account**: Fetches the ARN of the ELB service account using the `aws_elb_service_account` data source.
- **AWS Region Information**: Provides the current region's name and description using the `aws_region` data source.
- **AWS Partition Information**: Retrieves the AWS partition (e.g., `aws`, `aws-cn`, `aws-us-gov`) using the `aws_partition` data source.
- **Toggle Switches**: Boolean variables allow enabling or disabling each data source to optimize resource usage and performance.
- **Modular Structure**: Separates data sources (`main.tf`) and outputs (`outputs.tf`) for better maintainability.

## Requirements
- Terraform >= 0.12
- AWS provider configured with valid credentials and region.

## Module Structure
- `main.tf`: Defines all AWS data sources (`aws_caller_identity`, `aws_elb_service_account`, `aws_region`, `aws_partition`).
- `outputs.tf`: Contains all output definitions for retrieved data.
- `vars.tf`: Defines configurable variables with toggle switches.
- `README.md`: This documentation file.

## Usage
To use this module in your Terraform configuration, include the following:

```hcl
module "aws_account_info" {
  source = "./path/to/AWSAccountModule"

  # Optional: Configure toggle switches
  enable_caller_identity      = true
  enable_elb_service_account = true
  enable_region_info         = true
  enable_partition_info      = true
}

output "account_id" {
  value = module.aws_account_info.aws_account_id
}

output "region_name" {
  value = module.aws_account_info.aws_region_name
}
```

## Variables
The module provides boolean variables to enable or disable specific data sources, allowing users to fetch only the required information.

| Name                        | Description                                      | Type  | Default |
|-----------------------------|--------------------------------------------------|-------|---------|
| `enable_caller_identity`    | Enable retrieval of caller identity information (account ID, ARN, user ID) | bool  | `true`  |
| `enable_elb_service_account`| Enable retrieval of ELB service account ARN       | bool  | `true`  |
| `enable_region_info`        | Enable retrieval of AWS region name and description | bool  | `true`  |
| `enable_partition_info`     | Enable retrieval of AWS partition information     | bool  | `true`  |

## Outputs
The module provides the following outputs, which return `null` if their corresponding data source is disabled.

| Name                     | Description                                      |
|--------------------------|--------------------------------------------------|
| `aws_account_id`         | The AWS account ID                               |
| `aws_caller_arn`         | The ARN of the caller identity                   |
| `aws_caller_user`        | The user ID of the caller                        |
| `elb_account_id`         | The ARN of the ELB service account               |
| `aws_region_name`        | The name of the current AWS region (e.g., `us-east-1`) |
| `aws_region_description`  | The description of the current AWS region (e.g., `US East (N. Virginia)`) |
| `aws_partition`          | The AWS partition (e.g., `aws`, `aws-cn`, `aws-us-gov`) |

## Example
Below is an example of using the module with selective data sources enabled:

```hcl
provider "aws" {
  region = "us-east-1"
}

module "aws_account_info" {
  source = "./AWSAccountModule"

  # Enable only caller identity and region info
  enable_caller_identity      = true
  enable_elb_service_account = false
  enable_region_info         = true
  enable_partition_info      = false
}

output "account_id" {
  value = module.aws_account_info.aws_account_id
}

output "region_name" {
  value = module.aws_account_info.aws_region_name
}

output "region_description" {
  value = module.aws_account_info.aws_region_description
}
```

## Notes
- **Provider Configuration**: Ensure the AWS provider is configured with valid credentials and a region before using the module.
- **Toggle Switches**: Use the boolean variables to disable unnecessary data sources, reducing API calls and improving performance.
- **Null Outputs**: If a data source is disabled (e.g., `enable_region_info = false`), its corresponding outputs (e.g., `aws_region_name`, `aws_region_description`) will return `null`.
- **Reusability**: The module can be used in any Terraform project requiring AWS account, region, or partition information, making it suitable for infrastructure setups, policy definitions, or resource tagging.