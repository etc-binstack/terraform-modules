# VPC Peering Terraform Module

This Terraform module creates a VPC peering connection between two AWS VPCs, supporting both same-account and cross-account peering, as well as same-region and cross-region configurations. It includes options for DNS resolution, route table updates, and custom tagging, making it highly reusable for various AWS environments.

## Features
- **VPC Peering Connection**: Creates and manages a VPC peering connection between an owner and accepter VPC.
- **Cross-Account and Cross-Region Support**: Configures peering across different AWS accounts and regions.
- **DNS Resolution**: Optionally enables DNS resolution for both owner and accepter VPCs.
- **Route Table Updates**: Optionally updates route tables in both VPCs to route traffic through the peering connection.
- **Custom Tagging**: Supports custom tags for all resources.
- **Conditional Deployment**: Toggle module deployment with `enable_module`.
- **Timeouts**: Configurable timeouts for peering connection creation and deletion.
- **Validation**: Input validation for critical variables like VPC IDs and CIDR blocks.

## Requirements
- Terraform >= 1.0
- AWS Provider >= 4.0
- Valid AWS credentials for both owner and accepter accounts (configured via profiles or other authentication methods).

## Usage
```hcl
module "vpc_peering" {
  source                   = "./path/to/module"
  enable_module            = true
  owner_profile            = "owner-account"
  owner_vpc_id             = "vpc-1234567890abcdef0"
  accepter_profile         = "accepter-account"
  acceptor_region          = "us-west-2"
  accepter_vpc_id          = "vpc-0987654321fedcba0"
  auto_accept              = true
  modify_owner_routetable  = true
  modify_accepter_routetable = true
  owner_route_table_ids    = ["rtb-12345678"]
  accepter_route_table_ids = ["rtb-87654321"]
  owner_cidr_block         = "10.0.0.0/16"
  accepter_cidr_block      = "192.168.0.0/16"
  allow_owner_dns_resolution    = true
  allow_accepter_dns_resolution = true
  tags = {
    Environment = "Production"
    Project     = "VPC-Peering"
  }
}
```

## Variables
| Name                        | Description                                                  | Type           | Default | Required |
|-----------------------------|--------------------------------------------------------------|----------------|---------|----------|
| `enable_module`             | Whether to deploy the module                                 | `bool`         | `false` | No       |
| `owner_profile`             | AWS Profile for the owner account                            | `string`       |         | Yes      |
| `owner_vpc_id`              | The VPC ID of the owner account                              | `string`       |         | Yes      |
| `accepter_profile`          | AWS Profile for the accepter account                         | `string`       |         | Yes      |
| `acceptor_region`           | The AWS region of the accepter VPC                           | `string`       |         | Yes      |
| `accepter_vpc_id`           | The VPC ID of the accepter account                           | `string`       |         | Yes      |
| `auto_accept`               | Automatically accept the peering connection                   | `bool`         | `false` | No       |
| `modify_owner_routetable`   | Add/Update route entry to owner route table                  | `bool`         | `false` | No       |
| `modify_accepter_routetable`| Add/Update route entry to accepter route table               | `bool`         | `false` | No       |
| `owner_route_table_ids`     | List of owner route table IDs to update                      | `list(string)` | `[]`    | No       |
| `accepter_route_table_ids`  | List of accepter route table IDs to update                   | `list(string)` | `[]`    | No       |
| `owner_cidr_block`          | CIDR block of the owner VPC for route table entries          | `string`       | `""`    | No       |
| `accepter_cidr_block`       | CIDR block of the accepter VPC for route table entries       | `string`       | `""`    | No       |
| `allow_owner_dns_resolution`| Allow DNS resolution from accepter VPC to owner VPC          | `bool`         | `false` | No       |
| `allow_accepter_dns_resolution`| Allow DNS resolution from owner VPC to accepter VPC       | `bool`         | `false` | No       |
| `tags`                      | Custom tags to apply to all resources                        | `map(string)`  | `{}`    | No       |

## Outputs
| Name                           | Description                                                  |
|--------------------------------|--------------------------------------------------------------|
| `vpc_peering_connection_id`    | The ID of the VPC peering connection                         |
| `vpc_peering_connection_accepter_id` | The ID of the VPC peering connection on the accepter side |
| `accepter_account_id`          | The AWS account ID of the accepter VPC                       |
| `owner_dns_resolution_enabled` | Whether DNS resolution is enabled for the owner VPC          |
| `accepter_dns_resolution_enabled` | Whether DNS resolution is enabled for the accepter VPC    |
| `owner_route_tables_updated`   | List of owner route table IDs updated with peering routes    |
| `accepter_route_tables_updated`| List of accepter route table IDs updated with peering routes |

## Notes
- Ensure that the AWS credentials for both `owner_profile` and `accepter_profile` are configured in `~/.aws/credentials` or via environment variables.
- For cross-region peering, the `acceptor_region` must differ from the owner VPC's region.
- Route table updates require valid `owner_cidr_block` and `accepter_cidr_block` values.
- DNS resolution requires that both VPCs have DNS support and DNS hostnames enabled.

## Example
For a cross-account, same-region peering with route table updates and DNS resolution:
```hcl
module "vpc_peering" {
  source                   = "./path/to/module"
  enable_module            = true
  owner_profile            = "prod-account"
  owner_vpc_id             = "vpc-1234567890abcdef0"
  accepter_profile         = "dev-account"
  acceptor_region          = "us-east-1"
  accepter_vpc_id          = "vpc-0987654321fedcba0"
  auto_accept              = true
  modify_owner_routetable  = true
  modify_accepter_routetable = true
  owner_route_table_ids    = ["rtb-12345678", "rtb-23456789"]
  accepter_route_table_ids = ["rtb-87654321", "rtb-98765432"]
  owner_cidr_block         = "10.0.0.0/16"
  accepter_cidr_block      = "192.168.0.0/16"
  allow_owner_dns_resolution    = true
  allow_accepter_dns_resolution = true
  tags = {
    Environment = "Production"
    Project     = "Cross-Account-Peering"
  }
}
```