# VPC Module

This Terraform module creates a customizable VPC in AWS, including public, private, and isolated subnets across multiple Availability Zones (AZs). It also provisions associated resources such as Internet Gateways (IGW), NAT Gateways (NGW), route tables, VPC Flow Logs (optional), and a DB Subnet Group (optional). The module supports conditional deployment and VPC peering routes.

The module is designed to be generic but includes some environment-specific logic (e.g., NAT Gateway provisioning based on the `environment` and `environment_alias` variables). It aims to provide a foundational VPC setup suitable for development, production, or other environments.

## Features
- Creates a VPC with a specified CIDR block.
- Deploys subnets in multiple AZs: public (with auto-assigned public IPs), private (routed via NAT Gateways), and isolated (no internet access).
- Provisions an Internet Gateway for public subnets.
- Creates NAT Gateways: One per AZ in production environments (except DR sites), or a single one otherwise.
- Sets up route tables for public, private, and isolated subnets, with optional peering routes.
- Optional VPC Flow Logs to CloudWatch Logs.
- Optional DB Subnet Group using isolated subnets.
- Restricts the default security group to block all traffic.
- Outputs key resource IDs for integration with other modules.

## Prerequisites
- Terraform v1.0+.
- AWS Provider v4.0+ configured with appropriate credentials and region.
- Ensure the AWS region has at least as many AZs as specified in `az_count`.

## Usage
To use this module, create a Terraform configuration that references it. Below is an example:

```hcl
module "vpc" {
  source = "./path/to/this/module"  # Replace with your module path (e.g., Git repo)

  enable_module           = true
  enable_peering_route    = false
  pcx_routes              = []  # List of peering routes if needed
  vpc_flowlogs_enable     = true
  db_subnetgroup_enable   = true

  environment             = "dev"
  environment_alias       = null
  vpc_name_prefix         = "myvpc"
  tags                    = {
    Project = "MyProject"
  }

  az_count                = 2
  vpc_cidr                = "10.0.0.0/16"
  subnet_cidr_block       = 8  # For /24 subnets
  db_subnet_group_name    = "my-db-subnet-group"
  vpc_flowlogs_name       = "my-vpc-flowlogs"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
```

Run `terraform init`, `terraform plan`, and `terraform apply` to deploy.

**Note:** There is a potential bug in subnet CIDR calculation for isolated subnets, which may cause overlaps with private subnets when `az_count > 1`. Review and adjust the `cidrsubnet` offsets in `vpc.tf` (e.g., set isolated offsets to start at `2 * var.az_count + count.index`).

## Validation as a Generic Module
This module is reasonably generic for creating a standard VPC setup but has some limitations:
- **Strengths:**
  - Conditional enabling/disabling of the entire module or features (e.g., Flow Logs, DB Subnet Group).
  - Supports multi-AZ deployments for high availability.
  - Flexible tagging and naming conventions.
  - Handles VPC peering routes dynamically.
  - Outputs are comprehensive and conditional (return `null` if module is disabled).

- **Weaknesses/Improvements Needed:**
  - Environment-specific logic (e.g., NAT Gateway count based on `environment == "prod"` and `environment_alias != "DRsite"`) reduces generality. Consider making this configurable via a separate variable.
  - Subnet CIDR calculation has a bug: Isolated subnets may overlap with private ones (e.g., for `az_count=3`, private ends at offset 5, isolated starts at 5). Fix by adjusting offsets to non-overlapping ranges (e.g., public: 0–n-1, private: n–2n-1, isolated: 2n–3n-1).
  - Naming conventions rely on `vpc_name_prefix` and `environment`, which may not fit all use cases.
  - No support for custom subnet counts per type or advanced features like IPv6, DNS support customization, or endpoint provisioning.
  - Flow Logs use a random ID for uniqueness, but retention is hardcoded to 60 days.
  - Default security group is restricted but could allow optional rules.
  - Overall, it's good for basic use but could be more flexible by extracting environment logic and fixing CIDR math.

To make it more generic, refactor hardcoded conditions and add tests (e.g., via Terratest).

## Input Variables
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `enable_module` | Whether to deploy the module or not | `bool` | `false` | No |
| `enable_peering_route` | Whether to deploy the module or not | `bool` | `false` | No |
| `pcx_routes` | List of routes to be added to private route tables. | `list(object({ cidr_block = string, vpc_peering_id = string }))` | `[]` | No |
| `vpc_flowlogs_enable` | Whether to enable VPC flow logs (true or false) | `bool` | N/A | Yes |
| `db_subnetgroup_enable` | Whether to create the database subnet group (true or false) | `bool` | N/A | Yes |
| `environment` | The environment name (e.g., 'dev', 'prod') for tag filtering and resource naming. | `string` | N/A | Yes |
| `environment_alias` | The environment name (e.g., 'dev', 'prod') for tag filtering and resource naming. | `string` | `"null"` | No |
| `vpc_name_prefix` | Prefix for naming resources associated with the VPC. | `string` | N/A | Yes |
| `tags` | Tags to be applied to all resources created by this module. | `map(string)` | N/A | Yes |
| `az_count` | The number of Availability Zones (AZs) to deploy resources across. | `number` | N/A | Yes |
| `vpc_cidr` | The CIDR block for the VPC (e.g., '10.0.0.0/16'). | `string` | N/A | Yes |
| `subnet_cidr_block` | The CIDR block size for each subnet (e.g., 8 for a /24 subnet size). | `number` | N/A | Yes |
| `db_subnet_group_name` | The name to assign to the database subnet group. | `string` | N/A | Yes |
| `vpc_flowlogs_name` | The name to assign to the VPC Flow Logs log group. | `string` | N/A | Yes |

## Outputs
| Name | Description | Value |
|------|-------------|-------|
| `vpc_id` | VPC ID | `var.enable_module ? aws_vpc.vpc[*].id : null` |
| `vpc_cidr` | VPC CIDR range | `var.enable_module ? aws_vpc.vpc[*].cidr_block : null` |
| `public_subnet_ids` | Public Subnet IDs | `var.enable_module ? aws_subnet.public[*].id : null` |
| `private_subnet_ids` | Private Subnet IDs | `var.enable_module ? aws_subnet.private[*].id : null` |
| `isolated_subnet_ids` | Isolated Subnet IDs | `var.enable_module ? aws_subnet.isolated[*].id : null` |
| `internet_gateway_id` | Internet Gateway ID | `var.enable_module ? aws_internet_gateway.igw[*].id : null` |
| `nat_gateway_ids` | NAT Gateway IDs | `var.enable_module ? aws_nat_gateway.ngw[*].id : null` |
| `public_route_table_id` | Route Table IDs for Public Subnets | `var.enable_module ? aws_route_table.public[*].id : null` |
| `private_route_table_ids` | Route Table IDs for Private Subnets | `var.enable_module ? aws_route_table.private[*].id : null` |
| `isolated_route_table_ids` | Route Table IDs for Isolated Subnets | `var.enable_module ? aws_route_table.isolated_rtb[*].id : null` |
| `vpc_flowlogs_log_group_arn` | VPC Flow Logs Log Group ARN (if enabled) | `var.enable_module && var.vpc_flowlogs_enable ? aws_cloudwatch_log_group.flowlogs[*].arn : null` |
| `db_subnet_group_name` | DB Subnet Group Name (if enabled) | `var.enable_module && var.db_subnetgroup_enable ? aws_db_subnet_group.subnet_group[*].name : null` |
| `priv_subnet_cidr` | Priv Subnet CIDR | `var.enable_module ? aws_subnet.private[*].cidr_block : null` |

## Deployment Tips
- **Testing:** Start with `enable_module = true` and minimal `az_count` (e.g., 2) in a non-production environment.
- **Peering:** If using `enable_peering_route`, provide `pcx_routes` as a list of objects with valid peering connection IDs.
- **Cost Considerations:** NAT Gateways and Flow Logs incur costs. Disable them if not needed.
- **Troubleshooting:** If subnets overlap, inspect CIDR calculations. Ensure `vpc_cidr` is large enough for the subnet size and AZ count (e.g., /16 VPC with /24 subnets needs at least 3*az_count available /24 blocks).
- **Cleanup:** Run `terraform destroy` to remove resources. Note that some resources (e.g., EIPs) may need manual release if stuck.
- **Extensions:** This module can be extended for VPC endpoints, security groups, or NACLs as needed.

For issues or contributions, refer to the source code in `vpc.tf`, `vars.tf`, and `outputs.tf`.



## BUG FIX
### Version 1:
bug: Peering route can only add into the single routetable `aws_route_table.private[0].id` in this below code. In `Version 2` the issue has resolved.

```hcl
resource "aws_route" "private_pcx" {
  count                     = var.enable_module && var.enable_peering_route && length(var.pcx_routes) > 0 ? length(var.pcx_routes) : 0
  route_table_id            = var.environment == "prod" ? element(aws_route_table.private.*.id, count.index) : element(aws_route_table.private.*.id, 0)
  destination_cidr_block    = var.pcx_routes[count.index].cidr_block
  vpc_peering_connection_id = var.pcx_routes[count.index].vpc_peering_id
}
```

### Version 2:
```hcl
# Create routes for VPC peering connections
resource "aws_route" "private_pcx" {
  # Calculate total number of routes needed:
  # For prod: number of route tables (az_count) × number of peering connections
  # For non-prod: 1 route table × number of peering connections
  count = var.enable_module && var.enable_peering_route && length(var.pcx_routes) > 0 ? (
    var.environment == "prod" ? (var.az_count * length(var.pcx_routes)) : length(var.pcx_routes)
  ) : 0

  # For prod: distribute routes across all route tables
  # For non-prod: all routes go to the single route table
  route_table_id = var.environment == "prod" ? (
    element(aws_route_table.private.*.id, floor(count.index / length(var.pcx_routes)))
  ) : aws_route_table.private[0].id

  destination_cidr_block    = var.pcx_routes[count.index % length(var.pcx_routes)].cidr_block
  vpc_peering_connection_id = var.pcx_routes[count.index % length(var.pcx_routes)].vpc_peering_id
}
```
