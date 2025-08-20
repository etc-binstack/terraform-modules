# ECR Registry Terraform Module

This Terraform module manages AWS Elastic Container Registry (ECR) repositories. It supports both creating new repositories and fetching existing ones, with configurable features like image scanning, lifecycle policies, and encryption. The module is designed to be reusable across different environments and projects.

## Features
- Create or fetch ECR repositories based on a toggle (`create_repositories`).
- Enable/disable image scanning on push.
- Enable/disable lifecycle policies with a customizable policy JSON.
- Support for AES256 or KMS encryption.
- Tagging for resource tracking and organization.
- Outputs for repository URIs, ARNs, and names.

## Requirements
- Terraform >= 1.0
- AWS provider >= 4.0
- AWS credentials configured with appropriate permissions for ECR.

## Usage
```hcl
module "ecr" {
  source              = "./path/to/module"
  ecr_repository_names = ["app1", "app2"]
  environment         = "prod"
  creator             = "team-x"
  project             = "my-project"
  create_repositories = true
  enable_image_scanning = true
  enable_lifecycle_policy = true
  encryption_type     = "KMS"
  kms_key             = "arn:aws:kms:region:account-id:key/key-id"
  tags = {
    CostCenter = "12345"
  }
}
```

## Inputs
| Name                   | Description                                                  | Type           | Default         | Required |
|------------------------|--------------------------------------------------------------|----------------|-----------------|----------|
| `ecr_repository_names` | List of ECR repository names to manage or fetch.             | `list(string)` | `[]`            | Yes      |
| `environment`          | Environment name for tagging (e.g., dev, prod).              | `string`       | `"dev"`         | No       |
| `creator`              | Creator identifier for tagging.                              | `string`       | `"terraform"`   | No       |
| `project`              | Project name for tagging.                                    | `string`       | `"default"`     | No       |
| `create_repositories`  | Whether to create new repositories or fetch existing ones.   | `bool`         | `true`          | No       |
| `enable_image_scanning`| Enable image scanning on push.                               | `bool`         | `true`          | No       |
| `enable_lifecycle_policy` | Enable lifecycle policy for image retention.              | `bool`         | `true`          | No       |
| `lifecycle_policy`     | JSON string for the ECR lifecycle policy.                    | `string`       | See default     | No       |
| `encryption_type`      | Encryption type for repositories (AES256 or KMS).            | `string`       | `"AES256"`      | No       |
| `kms_key`              | KMS key ARN for encryption if `encryption_type` is KMS.     | `string`       | `null`          | No       |
| `tags`                 | Additional tags to apply to all resources.                   | `map(string)`  | `{}`            | No       |

## Outputs
| Name                   | Description                                   |
|------------------------|-----------------------------------------------|
| `ecr_repository_uris`  | List of ECR repository URIs.                  |
| `ecr_repository_arns`  | List of ECR repository ARNs.                  |
| `ecr_repository_names` | List of ECR repository names.                 |

## Example
### Create Two ECR Repositories
```hcl
module "ecr" {
  source              = "./path/to/module"
  ecr_repository_names = ["frontend", "backend"]
  environment         = "staging"
  project             = "web-app"
  create_repositories = true
  enable_image_scanning = true
  enable_lifecycle_policy = true
  tags = {
    Owner = "DevTeam"
  }
}
```

### Fetch Existing Repositories
```hcl
module "ecr" {
  source              = "./path/to/module"
  ecr_repository_names = ["existing-repo"]
  create_repositories = false
}
```

## Notes
- Ensure the AWS provider is configured with the appropriate region and credentials.
- If using KMS encryption, provide a valid KMS key ARN.
- The default lifecycle policy keeps the last 30 images; customize as needed.
- If `create_repositories` is `false`, the module assumes the repositories exist and fetches them using a `data` source.