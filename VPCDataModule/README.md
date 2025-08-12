# AWS VPC Existing Resources Module

This Terraform module provides a standardized way to reference and gather information about existing AWS VPC resources. It's designed to be reusable across different environments and projects.

## Features

- **Flexible Configuration**: Support for multiple environments with different configurations
- **Comprehensive Data Sources**: Gathers information about VPC, subnets, gateways, route tables, and more
- **Optional Lookups**: Configure which resources to lookup to optimize performance
- **Rich Outputs**: Provides detailed information about all VPC components
- **Validation**: Input validation for better error handling
- **Tagging Support**: Additional tags can be applied consistently

## Usage

### Basic Usage

```hcl
module "existing_vpc" {
  source = "./modules/VPCDataModule"

  environment = "dev"
  vpc_id      = "vpc-09cac06688a7c379e"
  
  public_subnet_ids   = ["subnet-09b2be4372e880054", "subnet-0c34d5e4b72e1ec18"]
  private_subnet_ids  = ["subnet-06655ef8f5c479a7e", "subnet-029f142c4068f8470"]
  isolated_subnet_ids = ["subnet-077a3405ca4112ad4", "subnet-02d1da3f757578709"]
  
  internet_gateway_id = "igw-06f70b7d5989259ce"
}
```

### Advanced Usage with Configuration Map

```hcl
locals {
  vpc_configs = {
    dev = {
      vpc_id              = "vpc-dev123"
      public_subnet_ids   = ["subnet-dev1", "subnet-dev2"]
      private_subnet_ids  = ["subnet-dev3", "subnet-dev4"]
      internet_gateway_id = "igw-dev123"
    }
    prod = {
      vpc_id              = "vpc-prod123"
      public_subnet_ids   = ["subnet-prod1", "subnet-prod2"]
      private_subnet_ids  = ["subnet-prod3", "subnet-prod4"]
      internet_gateway_id = "igw-prod123"
    }
  }
}

module "existing_vpc" {
  source = "./modules/VPCDataModule"

  environment = var.environment
  vpc_id      = local.vpc_configs[var.environment].vpc_id
  
  public_subnet_ids  = local.vpc_configs[var.environment].public_subnet_ids
  private_subnet_ids = local.vpc_configs[var.environment].private_subnet_ids
  
  internet_gateway_id = local.vpc_configs[var.environment].internet_gateway_id
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_module` | Whether to enable this module | `bool` | `true` | no |
| `environment` | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| `vpc_id` | ID of the existing VPC | `string` | n/a | yes |
| `public_subnet_ids` | List of existing public subnet IDs | `list(string)` | `[]` | no |
| `private_subnet_ids` | List of existing private subnet IDs | `list(string)` | `[]` | no |
| `isolated_subnet_ids` | List of existing isolated subnet IDs | `list(string)` | `[]` | no |
| `internet_gateway_id` | ID of the existing Internet Gateway | `string` | `null` | no |
| `internet_gateway_name_tag` | Name tag of the Internet Gateway to lookup | `string` | `null` | no |
| `route_table_name_prefix` | Prefix for route table names | `string` | `"demoproject"` | no |
| `db_subnet_group_name` | Name of the existing DB subnet group | `string` | `null` | no |
| `lookup_nat_gateways` | Whether to lookup NAT gateways | `bool` | `true` | no |
| `lookup_route_tables` | Whether to lookup route tables | `bool` | `true` | no |
| `lookup_db_subnet_group` | Whether to lookup DB subnet group | `bool` | `false` | no |
| `additional_tags` | Additional tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `vpc_arn` | ARN of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `isolated_subnet_ids` | List of isolated subnet IDs |
| `public_subnet_cidr_blocks` | List of public subnet CIDR blocks |
| `private_subnet_cidr_blocks` | List of private subnet CIDR blocks |
| `isolated_subnet_cidr_blocks` | List of isolated subnet CIDR blocks |
| `public_subnet_availability_zones` | List of AZs for public subnets |
| `private_subnet_availability_zones` | List of AZs for private subnets |
| `isolated_subnet_availability_zones` | List of AZs for isolated subnets |
| `internet_gateway_id` | ID of the Internet Gateway |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `nat_gateway_public_ips` | List of NAT Gateway public IPs |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_id` | ID of the private route table |
| `isolated_route_table_id` | ID of the isolated route table |
| `db_subnet_group_name` | Name of the DB subnet group |
| `db_subnet_group_arn` | ARN of the DB subnet group |
| `default_security_group_id` | ID of the default security group |
| `subnet_counts` | Count of subnets by type |
| `region` | AWS region |
| `availability_zones` | List of availability zones |

## Route Table Naming Convention

The module expects route tables to follow this naming convention:
- Public: `{environment}-{route_table_name_prefix}-pub-rtb`
- Private: `{environment}-{route_table_name_prefix}-priv-rtb`
- Isolated: `{environment}-{route_table_name_prefix}-isol-rtb`

For example, with `environment = "dev"` and `route_table_name_prefix = "demoproject"`:
- `dev-demoproject-pub-rtb`
- `dev-demoproject-priv-rtb`
- `dev-demoproject-isol-rtb`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Performance Optimization

To optimize performance, you can disable unnecessary lookups:

```hcl
module "existing_vpc" {
  source = "./modules/VPCDataModule"

  # ... other variables ...
  
  # Disable expensive lookups if not needed
  lookup_nat_gateways    = false
  lookup_route_tables    = false
  lookup_db_subnet_group = false
}
```

## Examples

See the `examples/` directory for complete usage examples.