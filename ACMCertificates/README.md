# AWS ACM Certificate Module

## Overview
This Terraform module provisions an AWS ACM certificate with optional Route53 DNS validation and configurable subject alternative names (SANs). It is designed to be reusable across different environments and projects, with toggle switches to enable or disable specific features.

## Features
- Creates a wildcard ACM certificate for a specified domain.
- Optionally validates the certificate using Route53 DNS records.
- Supports configurable subject alternative names (SANs) with a toggle switch.
- Includes input validation for the domain name.
- Outputs certificate ID, ARN, and validation status for use in other modules.

## Requirements
- Terraform >= 1.0
- AWS provider >= 4.0
- An existing Route53 hosted zone (if `route53_validation` is enabled)

## Usage
```hcl
module "acm_certificate" {
  source = "./path/to/module"

  domain_name               = "example.com"
  enable_module             = true
  route53_validation        = true
  enable_sans               = true
  subject_alternative_names = ["www.example.com", "api.example.com"]
  tags = {
    Environment = "Production"
    Project     = "MyApp"
  }
}
```

## Inputs
| Name                      | Description                                         | Type          | Default     | Required |
|---------------------------|-----------------------------------------------------|---------------|-------------|----------|
| `tags`                    | A map of tags to associate with the resources       | `map(string)` | `{}`        | No       |
| `domain_name`             | The domain name for the hosted zone                 | `string`      | -           | Yes      |
| `enable_module`           | A flag to enable or disable the module              | `bool`        | `false`     | No       |
| `route53_validation`      | A flag to enable or disable Route53 validation       | `bool`        | `true`      | No       |
| `enable_sans`             | A flag to enable or disable subject alternative names| `bool`        | `true`      | No       |
| `subject_alternative_names`| List of subject alternative names for the certificate| `list(string)`| `[]`        | No       |

## Outputs
| Name                     | Description                                      |
|--------------------------|--------------------------------------------------|
| `acm_certificate_id`     | The ID of the ACM certificate                    |
| `acm_certificate_arn`    | The ARN of the ACM certificate                   |
| `acm_validation_status`  | The validation status of the ACM certificate     |

## Notes
- The `domain_name` must be a valid domain (e.g., `example.com`).
- If `route53_validation` is enabled, ensure the Route53 hosted zone exists.
- The module supports wildcard certificates (e.g., `*.example.com`) by default.
- Set `enable_module = false` to disable resource creation entirely.
- Set `enable_sans = false` to exclude subject alternative names.

## Example
To create a certificate for `example.com` with Route53 validation and additional SANs:
```hcl
module "acm_certificate" {
  source = "./path/to/module"

  domain_name               = "example.com"
  enable_module             = true
  route53_validation        = true
  enable_sans               = true
  subject_alternative_names = ["www.example.com"]
  tags = {
    Environment = "Production"
  }
}
```

To validate that the provided Terraform configuration is a reusable module and to ensure all features have toggle switches for enabling/disabling, I'll review the existing code and suggest improvements. The module creates an AWS ACM certificate with optional Route53 validation, which is a good start for reusability. However, there are a few areas where the module can be enhanced to ensure it is fully reusable and robust:

1. **Missing Toggle Switches**: The module already has `enable_module` and `route53_validation` as toggle switches, which is good. However, additional features like subject alternative names (SANs) configuration could be made optional with a toggle or dynamic input to make the module more flexible.
2. **Input Validation**: The `domain_name` variable lacks validation to ensure it’s a valid domain, which could improve robustness.
3. **Output Enhancements**: The `outputs.tf` file only outputs the ACM certificate ID. Including the ARN and validation status could make the module more reusable.
4. **Error Handling**: The module assumes certain resources exist (e.g., Route53 zone). Adding checks or fallbacks could enhance reusability.
5. **Documentation**: A `README.markdown` file is required to explain the module’s purpose, inputs, outputs, and usage, ensuring it can be used anywhere.

### Proposed Changes
- **Add a toggle for subject alternative names**: Introduce a variable to optionally include SANs.
- **Add input validation for domain_name**: Ensure the domain name is valid.
- **Enhance outputs**: Include the certificate ARN and validation status.
- **Update vars.tf**: Add the new SAN toggle variable and validation for `domain_name`.
- **Generate README.markdown**: Provide comprehensive documentation.

Below are the updated files and the new README.

<xaiArtifact artifact_id="2a27df14-1d35-4ed3-912e-23db4906ed5e" artifact_version_id="ce9bf010-5248-4bce-a852-fa369bb85b50" title="vars.tf" contentType="text/plain">
variable "tags" {
  description = "A map of tags to associate with the resources"
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  type        = string
  description = "The domain name for the hosted zone"

  validation {
    condition     = length(regexall("^[a-zA-Z0-9][a-zA-Z0-9-.]{1,61}[a-zA-Z0-9](?:\\.[a-zA-Z]{2,})+$", var.domain_name)) > 0
    error_message = "The domain_name must be a valid domain name (e.g., example.com)."
  }
}

variable "enable_module" {
  description = "A flag to enable or disable the module"
  type        = bool
  default     = false
}

variable "route53_validation" {
  description = "A flag to enable or disable Route53 validation"
  type        = bool
  default     = true
}

variable "enable_sans" {
  description = "A flag to enable or disable subject alternative names"
  type        = bool
  default     = true
}

variable "subject_alternative_names" {
  description = "List of subject alternative names for the certificate"
  type        = list(string)
  default     = []
}
</xaiArtifact>

<xaiArtifact artifact_id="19cdd8c4-e820-4ee8-87ce-3920dc62977f" artifact_version_id="bbabe00f-91ec-464e-b687-1e61a93e5997" title="outputs.tf" contentType="text/plain">
output "acm_certificate_id" {
  description = "The ID of the ACM certificate"
  value       = var.enable_module ? aws_acm_certificate.certs[0].id : null
}

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = var.enable_module ? aws_acm_certificate.certs[0].arn : null
}

output "acm_validation_status" {
  description = "The validation status of the ACM certificate"
  value       = var.enable_module && var.route53_validation && length(aws_acm_certificate_validation.certs) > 0 ? aws_acm_certificate_validation.certs[0].validation_status : "Not Validated"
}
</xaiArtifact>

<xaiArtifact artifact_id="d1278916-d7c3-463a-a658-9e91ccd9b2f2" artifact_version_id="43c16938-e4b2-4eea-a4e6-90b38a60145e" title="acm.tf" contentType="text/plain">
## Generate wildcard certificate in ACM 
resource "aws_acm_certificate" "certs" {
  count                     = var.enable_module ? 1 : 0
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = var.enable_sans ? concat(["${var.domain_name}"], var.subject_alternative_names) : []
  validation_method         = var.route53_validation ? "DNS" : "NONE"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

## Validate ACM certificate using Route53 DNS
data "aws_route53_zone" "acm_domain" {
  count        = var.enable_module && var.route53_validation ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "certs" {
  for_each = var.enable_module && var.route53_validation && length(aws_acm_certificate.certs) > 0 ? {
    for dvo in aws_acm_certificate.certs[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.acm_domain[0].zone_id
}

resource "aws_acm_certificate_validation" "certs" {
  count                   = var.enable_module && var.route53_validation && length(aws_route53_record.certs) > 0 ? 1 : 0
  certificate_arn         = aws_acm_certificate.certs[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certs : record.fqdn]
}
</xaiArtifact>

<xaiArtifact artifact_id="aa028280-1919-4426-9254-d115064c417f" artifact_version_id="5d4048bf-7130-47e7-ba61-007a5bd34d4e" title="README.markdown" contentType="text/markdown">
# AWS ACM Certificate Module

## Overview
This Terraform module provisions an AWS ACM certificate with optional Route53 DNS validation and configurable subject alternative names (SANs). It is designed to be reusable across different environments and projects, with toggle switches to enable or disable specific features.

## Features
- Creates a wildcard ACM certificate for a specified domain.
- Optionally validates the certificate using Route53 DNS records.
- Supports configurable subject alternative names (SANs) with a toggle switch.
- Includes input validation for the domain name.
- Outputs certificate ID, ARN, and validation status for use in other modules.

## Requirements
- Terraform >= 1.0
- AWS provider >= 4.0
- An existing Route53 hosted zone (if `route53_validation` is enabled)

## Usage
```hcl
module "acm_certificate" {
  source = "./path/to/module"

  domain_name               = "example.com"
  enable_module             = true
  route53_validation        = true
  enable_sans               = true
  subject_alternative_names = ["www.example.com", "api.example.com"]
  tags = {
    Environment = "Production"
    Project     = "MyApp"
  }
}
```

## Inputs
| Name                      | Description                                         | Type          | Default     | Required |
|---------------------------|-----------------------------------------------------|---------------|-------------|----------|
| `tags`                    | A map of tags to associate with the resources       | `map(string)` | `{}`        | No       |
| `domain_name`             | The domain name for the hosted zone                 | `string`      | -           | Yes      |
| `enable_module`           | A flag to enable or disable the module              | `bool`        | `false`     | No       |
| `route53_validation`      | A flag to enable or disable Route53 validation       | `bool`        | `true`      | No       |
| `enable_sans`             | A flag to enable or disable subject alternative names| `bool`        | `true`      | No       |
| `subject_alternative_names`| List of subject alternative names for the certificate| `list(string)`| `[]`        | No       |

## Outputs
| Name                     | Description                                      |
|--------------------------|--------------------------------------------------|
| `acm_certificate_id`     | The ID of the ACM certificate                    |
| `acm_certificate_arn`    | The ARN of the ACM certificate                   |
| `acm_validation_status`  | The validation status of the ACM certificate     |

## Notes
- The `domain_name` must be a valid domain (e.g., `example.com`).
- If `route53_validation` is enabled, ensure the Route53 hosted zone exists.
- The module supports wildcard certificates (e.g., `*.example.com`) by default.
- Set `enable_module = false` to disable resource creation entirely.
- Set `enable_sans = false` to exclude subject alternative names.

## Example
To create a certificate for `example.com` with Route53 validation and additional SANs:
```hcl
module "acm_certificate" {
  source = "./path/to/module"

  domain_name               = "example.com"
  enable_module             = true
  route53_validation        = true
  enable_sans               = true
  subject_alternative_names = ["www.example.com"]
  tags = {
    Environment = "Production"
  }
}
```

### Explanation of Changes
1. **Toggle Switches**:
   - Added `enable_sans` variable to toggle subject alternative names.
   - Modified `aws_acm_certificate.certs` to conditionally include SANs based on `enable_sans`.
   - Kept `enable_module` and `route53_validation` as existing toggle switches.
2. **Input Validation**:
   - Added a `validation` block to `domain_name` to ensure it’s a valid domain using a regex pattern.
3. **Outputs**:
   - Renamed `acm_arn` to `acm_certificate_arn` for clarity.
   - Added `acm_certificate_id` and `acm_validation_status` to provide more information.
   - Outputs return `null` or a default value when the module is disabled.
4. **ACM Configuration**:
   - Set `validation_method` to `"NONE"` if `route53_validation` is disabled, improving flexibility.
   - Used `concat` to dynamically handle SANs, ensuring the primary domain is included only if `enable_sans` is true.
5. **README**:
   - Created a comprehensive `README.markdown` with usage instructions, input/output details, and examples.

### Validation of Reusability
- **Modularity**: The module is self-contained and can be used in any Terraform project with an AWS provider.
- **Flexibility**: Toggle switches (`enable_module`, `route53_validation`, `enable_sans`) allow users to customize behavior.
- **Portability**: No hard-coded values; all inputs are configurable via variables.
- **Documentation**: The README ensures users can easily understand and integrate the module.
- **Error Handling**: Input validation and conditional resource creation prevent common errors.