# DNSRoute53Module

This Terraform module provides a reusable solution for managing AWS Route 53 hosted zones, supporting both public and private zones. It allows creating new zones, associating existing private zones with a VPC, and fetching existing zones for reference. The module consolidates functionality from four scenarios: creating new public zones (`DNSPublicZone`), creating new private zones (`DNSPrivateZone`), associating existing private zones (`DNSPrivateZoneExg`), and fetching existing public zones (`DNSPublicZoneExg`).

## Features
- Create new public Route 53 hosted zones.
- Create new private Route 53 hosted zones and associate them with a VPC.
- Associate existing private Route 53 hosted zones with a VPC.
- Fetch existing public or private Route 53 hosted zones using data sources.
- Support for tagging created resources.
- Conditional logic to enable/disable public or private zone functionality.

## Prerequisites
- Terraform >= 1.0.0
- AWS provider configured with appropriate credentials and permissions for Route 53 and VPC management.
- Valid AWS Route 53 zone IDs for existing zones (if using `use_existing_public_zone` or `use_existing_private_zone`).
- A valid VPC ID for private zone creation or association.

## Module Structure
The module consists of the following files:
- `dns.tf`: Defines resources and data sources for public and private Route 53 hosted zones.
- `vars.tf`: Declares input variables for configuring the module.
- `outputs.tf`: Defines outputs for zone IDs and domain names.

## Input Variables
| Name                       | Type          | Description                                                                 | Default |
|----------------------------|---------------|-----------------------------------------------------------------------------|---------|
| `enable_public_zone`       | `bool`        | Whether to create or fetch a public Route 53 hosted zone                    | `false` |
| `enable_private_zone`      | `bool`        | Whether to create or associate a private Route 53 hosted zone               | `false` |
| `use_existing_public_zone` | `bool`        | Whether to use an existing public Route 53 hosted zone instead of creating  | `false` |
| `use_existing_private_zone`| `bool`        | Whether to use an existing private Route 53 hosted zone instead of creating | `false` |
| `public_domain_name`       | `string`      | Domain name for the public Route 53 hosted zone (used when creating)        | `""`    |
| `private_domain_name`      | `string`      | Domain name for the private Route 53 hosted zone (used when creating)       | `""`    |
| `existing_public_zone_id`  | `string`      | ID of an existing public Route 53 hosted zone (used when `use_existing_public_zone` is `true`) | `null` |
| `existing_private_zone_id` | `string`      | ID of an existing private Route 53 hosted zone (used when `use_existing_private_zone` is `true`) | `null` |
| `vpc_id`                   | `string`      | ID of the VPC to associate with the private Route 53 hosted zone           | `null`  |
| `tags`                     | `map(string)` | Map of tags to associate with created resources                            | `{}`    |

## Outputs
| Name                  | Description                                                  |
|-----------------------|--------------------------------------------------------------|
| `public_zone_id`      | ID of the public Route 53 hosted zone (created or fetched)   |
| `public_domain_name`  | Domain name of the public Route 53 hosted zone (created or fetched) |
| `private_zone_id`     | ID of the private Route 53 hosted zone (created or associated) |
| `private_domain_name` | Domain name of the private Route 53 hosted zone (created or fetched) |

## Usage Examples

### 1. Create New Public and Private Zones
Create a new public hosted zone for `example.com` and a new private hosted zone for `internal.example.com`, associated with a VPC.

```hcl
module "dns_route53" {
  source                 = "./modules/DNSRoute53Module"
  enable_public_zone     = true
  enable_private_zone    = true
  use_existing_public_zone  = false
  use_existing_private_zone = false
  public_domain_name     = "example.com"
  private_domain_name    = "internal.example.com"
  vpc_id                 = "vpc-12345678"
  tags                   = {
    Environment = "Production"
    Project     = "MyProject"
  }
}
```

### 2. Fetch Existing Public Zone and Associate Existing Private Zone
Fetch an existing public zone and associate an existing private zone with a VPC.

```hcl
module "dns_route53" {
  source                    = "./modules/DNSRoute53Module"
  enable_public_zone        = true
  enable_private_zone       = true
  use_existing_public_zone  = true
  use_existing_private_zone = true
  existing_public_zone_id   = "Z1234567890"
  existing_private_zone_id  = "Z0987654321"
  vpc_id                    = "vpc-12345678"
  tags                      = {
    Environment = "Production"
  }
}
```

### 3. Fetch Existing Public Zone Only
Fetch an existing public zone without creating or associating any private zones.

```hcl
module "dns_route53" {
  source                    = "./modules/DNSRoute53Module"
  enable_public_zone        = true
  enable_private_zone       = false
  use_existing_public_zone  = true
  existing_public_zone_id   = "Z1234567890"
}
```

### 4. Create Private Zone Only
Create a new private hosted zone without managing a public zone.

```hcl
module "dns_route53" {
  source                 = "./modules/DNSRoute53Module"
  enable_public_zone     = false
  enable_private_zone    = true
  use_existing_private_zone = false
  private_domain_name    = "internal.example.com"
  vpc_id                 = "vpc-12345678"
  tags                   = {
    Environment = "Staging"
  }
}
```

## Notes
- **Validation**: Ensure `existing_public_zone_id` and `existing_private_zone_id` are valid Route 53 zone IDs when `use_existing_public_zone` or `use_existing_private_zone` is `true`. Provide a valid `vpc_id` for private zone creation or association.
- **Tag Limitations**: The `data "aws_route53_zone"` resource does not support filtering by tags. If you need to select zones by tags, retrieve the `zone_id` using the AWS CLI (e.g., `aws route53 list-hosted-zones`) and pass it to the module.
- **Conditional Logic**: The module uses `count` to conditionally create or fetch resources, preventing errors when inputs are missing (e.g., null `existing_public_zone_id`).
- **Reusability**: The module supports all scenarios (creating new zones, fetching existing zones, or associating private zones) via toggle variables, making it suitable for any AWS Route 53 use case.

## Example Output
For the first example (creating new zones), the outputs might look like:
```hcl
Outputs:
public_zone_id      = "Z1A2B3C4D5E6F"
public_domain_name  = "example.com"
private_zone_id     = "Z6F5E4D3C2B1A"
private_domain_name = "internal.example.com"
```

## Troubleshooting
- **Invalid Zone ID**: If `existing_public_zone_id` or `existing_private_zone_id` is invalid, Terraform will error during the apply phase. Verify the IDs using the AWS Management Console or CLI.
- **Missing VPC ID**: Ensure `vpc_id` is provided when `enable_private_zone` is `true`, as it’s required for both creating and associating private zones.
- **No Tags in Data Source**: Tags are only applied to created resources (`aws_route53_zone`), not fetched ones (`data "aws_route53_zone"`), due to Terraform provider limitations.

For further assistance, refer to the [AWS Route 53 Terraform documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone).