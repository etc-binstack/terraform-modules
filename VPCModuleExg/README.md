# VPC Data Module

This Terraform module fetches existing AWS VPC resources using data sources. It is designed to retrieve details of an already provisioned VPC, including subnets (public, private, isolated), Internet Gateway (IGW), NAT Gateway (NGW), route tables, and a DB Subnet Group. This serves as a companion "data module" to a VPC creation module, allowing you to reference existing infrastructure in a generic way without recreating resources.

The module supports conditional fetching based on the `enable_module` flag and assumes a standard VPC setup. However, it includes some environment-specific filtering (e.g., resource names prefixed with `${var.environment}-${existing_vpc_tagname}`), which may need adjustment for full generality.

## Features
- Fetches an existing VPC by ID.
- Retrieves public, private, and isolated subnets by provided IDs.
- Fetches Internet Gateway, NAT Gateway, and route tables using filters (e.g., tags for names like `${var.environment}-${existing_vpc_tagname}-igw`).
- Optionally fetches a DB Subnet Group by name.
- Outputs fetched resource IDs and details, returning `null` if the module is disabled or resources are not found.
- Restricts fetching to specified AZ counts for subnets.

## Prerequisites
- Terraform v1.0+.
- AWS Provider v4.0+ configured with appropriate credentials and region.
- Existing VPC resources in AWS that match the provided IDs and filters.
- Ensure the AWS region has at least as many AZs as specified in `az_count`.

## Usage
To use this module, reference it in your Terraform configuration and provide the necessary existing resource IDs. Below is an example:

```hcl
module "vpc_data" {
  source = "./path/to/this/module"  # Replace with your module path (e.g., Git repo)

  enable_module                = true
  environment                  = "dev"
  az_count                     = 2
  existing_vpc_id              = "vpc-12345678"
  existing_public_subnet_ids   = ["subnet-abc123", "subnet-def456"]
  existing_private_subnet_ids  = ["subnet-ghi789", "subnet-jkl012"]
  existing_isolated_subnet_ids = ["subnet-mno345", "subnet-pqr678"]
  existing_igw_id              = "igw-xyz901"  # Note: Currently unused in the module; IGW is fetched by tags
  db_subnet_group_name         = "my-db-subnet-group"
}

output "vpc_id" {
  value = module.vpc_data.vpc_id
}
```

Run `terraform init`, `terraform plan`, and `terraform apply` to fetch the resources.

**Note:** The module fetches route tables and IGW using hardcoded name prefixes (e.g., `${existing_vpc_tagname}`). If your resources use different naming, update the filters in `vpc.tf`. Also, NAT Gateway fetching is limited to one (based on the first public subnet); extend the data source for multi-NAT setups.

## Validation as a Generic Module
This module is a good starting point for fetching existing VPC resources in a reusable way but has limitations that reduce its generality:
- **Strengths:**
  - Uses data sources only, avoiding any resource creation—ideal for read-only operations.
  - Conditional logic handles cases where resources might not exist (outputs `null`).
  - Supports multi-AZ subnet fetching via lists of IDs.
  - Outputs are lists where appropriate (e.g., subnet IDs), making it flexible for integration.

- **Weaknesses/Improvements Needed:**
  - Hardcoded name prefixes like `${existing_vpc_tagname}` in filters (e.g., for IGW and route tables) make it specific to a particular naming convention. To generalize, add a variable like `name_prefix` (default: "${existing_vpc_tagname}") and use it in filters, e.g., `tag:Name = "${var.environment}-${var.name_prefix}-igw"`.
  - Route tables are fetched as single instances (count=1 per type), but in multi-AZ/production setups, private route tables might be one per AZ. Update data sources to use loops (e.g., count=var.az_count for private RTBs) and dynamic filters based on AZ or tags.
  - NAT Gateway fetching is limited to one (tied to the first public subnet). For high-availability setups with one NAT per AZ, loop over all public subnets and fetch accordingly.
  - `existing_igw_id` variable is defined but unused; either remove it or use it to fetch IGW by ID instead of tags for more flexibility.
  - DB Subnet Group fetching assumes it exists; add error handling or optional flags.
  - No support for fetching VPC Flow Logs or other advanced resources; extend if needed.
  - Assumes single route tables for public/private/isolated; if your setup has multiple, adjust to fetch by associations or additional tags.
  - Overall, it's suitable for simple, single-RTB-per-type VPCs but needs refactoring for multi-AZ complexity (e.g., match the creation module's logic). Add Terratest for validation.

To enhance generality, introduce more variables for filters/tags and make fetching dynamic based on `az_count`. No major bugs, but test with real AWS resources to ensure filters match.

## Input Variables
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `enable_module` | Whether to deploy the module or not | `bool` | `false` | No |
| `environment` | The environment name (e.g., 'dev', 'prod') for tag filtering and resource naming. | `string` | N/A | Yes |
| `az_count` | The number of Availability Zones (AZs) to deploy resources across. | `number` | N/A | Yes |
| `existing_vpc_id` | The ID of the existing VPC | `string` | N/A | Yes |
| `existing_public_subnet_ids` | List of existing public subnet IDs | `list(string)` | N/A | Yes |
| `existing_private_subnet_ids` | List of existing private subnet IDs | `list(string)` | N/A | Yes |
| `existing_isolated_subnet_ids` | List of existing isolated subnet IDs | `list(string)` | N/A | Yes |
| `existing_igw_id` | The ID of the existing Internet Gateway | `string` | N/A | No (Unused) |
| `db_subnet_group_name` | The name to assign to the database subnet group. | `string` | `null` | No |

## Outputs
| Name | Description | Value |
|------|-------------|-------|
| `vpc_id` | VPC ID | `var.enable_module ? data.aws_vpc.existing_vpc[*].id : null` |
| `vpc_cidr` | VPC CIDR range | `var.enable_module ? data.aws_vpc.existing_vpc[*].cidr_block : null` |
| `public_subnet_ids` | Public Subnet IDs | `var.enable_module && length(data.aws_subnet.public) > 0 ? [for subnet in data.aws_subnet.public : subnet.id] : null` |
| `private_subnet_ids` | Private Subnet IDs | `var.enable_module && length(data.aws_subnet.private) > 0 ? [for subnet in data.aws_subnet.private : subnet.id] : null` |
| `isolated_subnet_ids` | Isolated Subnet IDs | `var.enable_module && length(data.aws_subnet.isolated) > 0 ? [for subnet in data.aws_subnet.isolated : subnet.id] : null` |
| `internet_gateway_id` | Internet Gateway ID | `var.enable_module ? data.aws_internet_gateway.igw[*].id : null` |
| `nat_gateway_ids` | NAT Gateway IDs | `var.enable_module && length(data.aws_nat_gateway.ngw) > 0 ? [for ngw in data.aws_nat_gateway.ngw : ngw.id] : null` |
| `public_route_table_id` | Route Table IDs for Public Subnets | `var.enable_module && length(data.aws_route_table.public) > 0 ? [for rt in data.aws_route_table.public : rt.id] : null` |
| `private_route_table_ids` | Route Table IDs for Private Subnets | `var.enable_module && length(data.aws_route_table.private) > 0 ? [for rt in data.aws_route_table.private : rt.id] : null` |
| `isolated_route_table_ids` | Route Table IDs for Isolated Subnets | `var.enable_module && length(data.aws_route_table.isolated) > 0 ? [for rt in data.aws_route_table.isolated : rt.id] : null` |
| `db_subnet_group_name` | The name of the DB Subnet Group (if enabled) | `var.enable_module && data.aws_db_subnet_group.subnet_group != null ? data.aws_db_subnet_group.subnet_group[*].name : null` |

## Deployment Tips
- **Testing:** Use with existing resources; verify outputs match your AWS console.
- **Integration:** Pair with a VPC creation module—use outputs to pass to other resources (e.g., EC2 instances).
- **Cost Considerations:** This module only fetches data, so no additional costs beyond AWS API calls.
- **Troubleshooting:** If data sources fail (e.g., "no matching resources"), check IDs, tags, and filters. Ensure `az_count` matches your subnet lists' length.
- **Extensions:** Add data sources for more resources like NACLs, security groups, or endpoints. Make filters configurable for different naming schemes.
- **Cleanup:** No resources created, so no destroy needed—just remove module calls.

For issues or contributions, refer to the source code in `vpc.tf`, `vars.tf`, and `outputs.tf`.