# AWS API Gateway VPC Link Terraform Module

A comprehensive, production-ready Terraform module for creating and managing AWS API Gateway VPC Links. This module provides a reusable, configurable solution for connecting API Gateway to private resources through Network Load Balancers.

## Features

- ✅ **Multiple Target Support**: Connect to multiple Network Load Balancers
- ✅ **Flexible Naming**: Auto-generated or custom names with optional prefixes/suffixes
- ✅ **Random Suffix**: Optional random suffix for unique naming
- ✅ **Comprehensive Tagging**: Default and custom tags support
- ✅ **Legacy Compatibility**: Backward compatible with existing implementations
- ✅ **Validation**: Built-in validation for ARNs and configurations
- ✅ **Enable/Disable Toggle**: Module-level enable/disable functionality
- ✅ **Rich Outputs**: Comprehensive outputs including NLB details
- ✅ **Production Ready**: Lifecycle rules and best practices included

## Usage

### Basic Usage

```hcl
module "vpc_link" {
  source = "./APIGatewayModules/VPCLinkModule"
  
  environment        = "dev"
  vpc_endpoint_name  = "api-backend"
  target_arns        = ["arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/my-nlb/1234567890123456"]
  
  tags = {
    Project = "my-project"
    Owner   = "platform-team"
  }
}
```

### Advanced Usage

```hcl
module "vpc_link_advanced" {
  source = "./APIGatewayModules/VPCLinkModule"
  
  # Module configuration
  enable_module = true
  
  # Naming configuration
  environment        = "prod"
  vpc_link_name      = "custom-vpc-link-name"  # Override auto-generated name
  name_prefix        = "company-"
  name_suffix        = "-v2"
  use_random_suffix  = true
  random_suffix_length = 4
  
  # VPC Link configuration
  vpclink_description = "VPC Link for production API gateway to internal services"
  target_arns = [
    "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/api-nlb/1234567890123456",
    "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/backup-nlb/9876543210987654"
  ]
  
  # Tagging
  tags = {
    Environment = "production"
    Project     = "api-platform"
    Owner       = "platform-team"
    CostCenter  = "engineering"
    Compliance  = "required"
  }
}
```

### Legacy Usage (Backward Compatibility)

```hcl
# This will continue to work with existing implementations
module "vpc_link_legacy" {
  source = "./APIGatewayModules/VPCLinkModule"
  
  environment        = "staging"
  vpc_endpoint_name  = "legacy-api"
  backend_nlb_arn    = "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/legacy-nlb/1234567890123456"
  vpclink_description = "Legacy VPC Link configuration"
  
  tags = {
    Environment = "staging"
    Legacy      = "true"
  }
}
```

## Migration Guide

### From Legacy Configuration

If you're currently using the legacy `backend_nlb_arn` variable, you can migrate to the new `target_arns` approach:

**Before (Legacy):**
```hcl
backend_nlb_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/my-nlb/1234567890123456"
```

**After (Recommended):**
```hcl
target_arns = ["arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/my-nlb/1234567890123456"]
```

The legacy configuration will continue to work but is deprecated.

## Examples

### Multiple Network Load Balancers

```hcl
module "multi_nlb_vpc_link" {
  source = "./APIGatewayModules/VPCLinkModule"
  
  environment       = "prod"
  vpc_endpoint_name = "multi-service"
  
  target_arns = [
    "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/service1-nlb/1111111111111111",
    "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/service2-nlb/2222222222222222",
    "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/service3-nlb/3333333333333333"
  ]
  
  tags = {
    Environment = "production"
    Services    = "multi"
  }
}
```

### Disabled Module (Conditional Creation)

```hcl
module "conditional_vpc_link" {
  source = "./APIGatewayModules/VPCLinkModule"
  
  enable_module = var.create_vpc_link  # Can be controlled by variable
  
  environment       = "dev"
  vpc_endpoint_name = "conditional"
  target_arns       = var.nlb_arns
  
  tags = var.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_vpc_link.vpclink](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link) | resource |
| [null_resource.validation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_lb.target_nlbs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backend_nlb_arn"></a> [backend\_nlb\_arn](#input\_backend\_nlb\_arn) | (DEPRECATED) Single backend NLB ARN. Use target\_arns instead for multiple targets support | `string` | `null` | no |
| <a name="input_enable_module"></a> [enable\_module](#input\_enable\_module) | Whether to deploy the VPC Link module or not | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Optional prefix for the VPC Link name | `string` | `""` | no |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Optional suffix for the VPC Link name | `string` | `""` | no |
| <a name="input_random_suffix_length"></a> [random\_suffix\_length](#input\_random\_suffix\_length) | Length of the random suffix when use\_random\_suffix is true | `number` | `3` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the VPC Link resource | `map(string)` | `{}` | no |
| <a name="input_target_arns"></a> [target\_arns](#input\_target\_arns) | List of target ARNs (Network Load Balancers) for the VPC Link | `list(string)` | `null` | no |
| <a name="input_use_random_suffix"></a> [use\_random\_suffix](#input\_use\_random\_suffix) | Whether to add a random suffix to the VPC Link name for uniqueness | `bool` | `true` | no |
| <a name="input_vpc_endpoint_name"></a> [vpc\_endpoint\_name](#input\_vpc\_endpoint\_name) | Base name for the VPC endpoint, used in auto-generated naming | `string` | n/a | yes |
| <a name="input_vpc_link_name"></a> [vpc\_link\_name](#input\_vpc\_link\_name) | Name for the VPC Link. If not provided, will be auto-generated using environment and vpc\_endpoint\_name | `string` | `null` | no |
| <a name="input_vpclink_description"></a> [vpclink\_description](#input\_vpclink\_description) | Description for the VPC Link | `string` | `"VPC Link for API Gateway to connect to private resources"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_computed_name"></a> [computed\_name](#output\_computed\_name) | The computed name used for the VPC Link |
| <a name="output_module_enabled"></a> [module\_enabled](#output\_module\_enabled) | Whether the VPC Link module is enabled |
| <a name="output_random_suffix"></a> [random\_suffix](#output\_random\_suffix) | The random suffix used in the VPC Link name (if enabled) |
| <a name="output_target_nlb_details"></a> [target\_nlb\_details](#output\_target\_nlb\_details) | Details of the target Network Load Balancers |
| <a name="output_vpc_link_arn"></a> [vpc\_link\_arn](#output\_vpc\_link\_arn) | The ARN of the VPC Link |
| <a name="output_vpc_link_description"></a> [vpc\_link\_description](#output\_vpc\_link\_description) | The description of the VPC Link |
| <a name="output_vpc_link_id"></a> [vpc\_link\_id](#output\_vpc\_link\_id) | The identifier of the VPC Link |
| <a name="output_vpc_link_name"></a> [vpc\_link\_name](#output\_vpc\_link\_name) | The name of the VPC Link |
| <a name="output_vpc_link_state"></a> [vpc\_link\_state](#output\_vpc\_link\_state) | The state of the VPC Link |
| <a name="output_vpc_link_tags"></a> [vpc\_link\_tags](#output\_vpc\_link\_tags) | The tags assigned to the VPC Link |
| <a name="output_vpc_link_target_arns"></a> [vpc\_link\_target\_arns](#output\_vpc\_link\_target\_arns) | The target ARNs of the VPC Link |
| <a name="output_vpclink_id"></a> [vpclink\_id](#output\_vpclink\_id) | (DEPRECATED) Use vpc\_link\_id instead |

## Validation Rules

The module includes several validation rules to ensure proper configuration:

1. **Environment Name**: Must not be empty
2. **VPC Endpoint Name**: Must not be empty
3. **Target ARNs**: If provided, must contain valid AWS Load Balancer ARNs
4. **Random Suffix Length**: Must be between 1 and 10
5. **Required Targets**: Either `target_arns` or `backend_nlb_arn` must be provided

## Best Practices

1. **Use Multiple Targets**: For high availability, consider using multiple Network Load Balancers
2. **Descriptive Naming**: Use meaningful names for easy identification
3. **Consistent Tagging**: Apply consistent tags across all resources
4. **Environment Separation**: Use different configurations for different environments
5. **State Management**: Use remote state backend for production deployments

## Troubleshooting

### Common Issues

1. **VPC Link Creation Fails**: Ensure the target NLB exists and is accessible
2. **Permission Errors**: Verify IAM permissions for API Gateway and Load Balancer services
3. **Name Conflicts**: Use random suffix or unique naming to avoid conflicts

### State Issues

If you encounter state issues during upgrades:

```bash
# View current state
terraform state list

# Import existing VPC Link if needed
terraform import 'module.vpc_link.aws_api_gateway_vpc_link.vpclink[0]' <vpc-link-id>
```

## Contributing

When contributing to this module:

1. Follow Terraform best practices
2. Update documentation for any new variables or outputs
3. Include examples for new features
4. Test with multiple provider versions
5. Validate with `terraform validate` and `terraform plan`

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Support

For questions or issues:

1. Check the troubleshooting section above
2. Review AWS API Gateway VPC Link documentation
3. Open an issue with detailed information about your use case

---

**Note**: This module supports both legacy configurations (using `backend_nlb_arn`) and modern configurations (using `target_arns`). While legacy support is maintained for backward compatibility, new implementations should use `target_arns` for better flexibility and future-proofing.
