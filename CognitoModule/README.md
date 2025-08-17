# AWS Cognito User Pool Module

This Terraform module provisions an AWS Cognito User Pool and associated resources, including a user pool client, with customizable configurations for authentication, MFA, account recovery, and more.

## Features

- Creates a Cognito User Pool with customizable attributes, schemas, and policies.
- Supports email or phone number as primary sign-in attributes.
- Configures password policies, MFA settings, and account recovery mechanisms.
- Supports Lambda triggers for post-authentication and pre-token generation.
- Generates random IDs and strings for unique resource naming.
- Provides outputs for user pool ID, name, ARN, client ID, and more.
- Conditional resource creation based on the `enable_module` variable.

## Prerequisites

- Terraform 1.0 or higher.
- AWS provider configured with appropriate credentials.
- AWS region that supports Cognito services.

## Usage

To use this module, include it in your Terraform configuration and provide the necessary variables.

### Example Module Usage

```hcl
module "cognito" {
  source = "./modules/cognito"

  enable_module       = true
  environment         = "dev"
  cognito_pool_name   = "my-user-pool"
  app_client_name     = "my-app-client"
  sign_in_attribute   = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection = "ACTIVE"
  case_sensitive_username = false

  custom_schemas = [
    {
      name                     = "custom_attribute"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = false
      min_length               = 1
      max_length               = 50
    }
  ]

  password_policy = {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  mfa_configuration   = "OPTIONAL"
  mfa_software_token  = true

  enable_account_recovery = true
  account_recovery_mechanisms = [
    {
      name     = "verified_email"
      priority = 1
    },
    {
      name     = "verified_phone_number"
      priority = 2
    }
  ]

  lambda_post_auth = "arn:aws:lambda:us-east-1:123456789012:function:post-auth"
  lambda_pre_token_generation = "arn:aws:lambda:us-east-1:123456789012:function:pre-token"
}
```

## Variables

| Name                          | Description                                                                 | Type                                    | Default       |
|-------------------------------|-----------------------------------------------------------------------------|-----------------------------------------|---------------|
| `enable_module`               | Whether to deploy the module or not                                         | `bool`                                  | `false`       |
| `environment`                 | Deployment environment (e.g., dev, prod)                                    | `string`                                |               |
| `cognito_pool_name`           | Name prefix for the Cognito user pool                                      | `string`                                |               |
| `app_client_name`             | Prefix for the app client name                                             | `string`                                |               |
| `sign_in_attribute`           | Primary sign-in attribute (email or phone_number)                           | `list(string)`                          | `[]`          |
| `auto_verified_attributes`    | Attributes to be auto-verified (email, phone_number)                        | `list(string)`                          | `[]`          |
| `deletion_protection`         | Prevents accidental deletion of user pool (`ACTIVE` or `INACTIVE`)          | `string`                                | `"INACTIVE"`  |
| `case_sensitive_username`     | Specifies whether username case sensitivity is applied                      | `bool`                                  | `false`       |
| `custom_schemas`              | List of custom schemas for the Cognito User Pool                           | `list(object)`                          | `[]`          |
| `password_policy`             | Password policy for the Cognito user pool                                   | `object`                                | `null`        |
| `mfa_configuration`           | Enable Multi-Factor Authentication (MFA) (`OFF`, `ON`, `OPTIONAL`)          | `string`                                | `"OFF"`       |
| `mfa_software_token`          | Enable software token for MFA                                               | `bool`                                  | `false`       |
| `enable_account_recovery`     | Whether to enable account recovery settings                                 | `bool`                                  | `false`       |
| `account_recovery_mechanisms` | List of recovery mechanisms with priorities (email or phone_number)         | `list(object)`                          | `[]`          |
| `lambda_post_auth`            | Lambda ARN for post-authentication trigger                                  | `string`                                | `""`          |
| `lambda_pre_token_generation` | Lambda ARN for pre-token generation trigger                                 | `string`                                | `""`          |

### Custom Schema Object

The `custom_schemas` variable accepts a list of objects with the following attributes:

| Name                     | Description                                    | Type     | Default |
|--------------------------|------------------------------------------------|----------|---------|
| `name`                   | Name of the custom attribute                   | `string` |         |
| `attribute_data_type`    | Data type of the attribute (e.g., `String`)     | `string` |         |
| `developer_only_attribute`| Whether the attribute is developer-only         | `bool`   |         |
| `mutable`                | Whether the attribute can be modified           | `bool`   |         |
| `required`               | Whether the attribute is required               | `bool`   |         |
| `min_length`             | Minimum length of the attribute value           | `number` |         |
| `max_length`             | Maximum length of the attribute value           | `number` |         |

### Password Policy Object

The `password_policy` variable accepts an object with the following attributes:

| Name                            | Description                                    | Type     | Default |
|---------------------------------|------------------------------------------------|----------|---------|
| `minimum_length`                | Minimum password length                        | `number` |         |
| `require_lowercase`             | Require lowercase characters                   | `bool`   |         |
| `require_numbers`               | Require numbers                                | `bool`   |         |
| `require_symbols`               | Require symbols                                | `bool`   |         |
| `require_uppercase`             | Require uppercase characters                   | `bool`   |         |
| `temporary_password_validity_days` | Validity period for temporary passwords (days) | `number` |         |

### Account Recovery Mechanism Object

The `account_recovery_mechanisms` variable accepts a list of objects with the following attributes:

| Name       | Description                                    | Type     | Default |
|------------|------------------------------------------------|----------|---------|
| `name`     | Recovery mechanism (e.g., `verified_email`)     | `string` |         |
| `priority` | Priority of the mechanism                      | `number` |         |

## Outputs

| Name                          | Description                                                  |
|-------------------------------|--------------------------------------------------------------|
| `cognito_user_pool_id`        | The ID of the created Cognito User Pool                      |
| `cognito_user_pool_name`      | The name of the created Cognito User Pool                    |
| `cognito_user_pool_arn`       | The ARN of the created Cognito User Pool                     |
| `cognito_user_pool_client_id` | The ID of the Cognito App Client                             |
| `cognito_user_pool_client_name` | The name of the Cognito App Client                         |
| `cognito_user_pool_client_secret` | The secret associated with the Cognito App Client         |
| `mfa_configuration`           | The MFA configuration of the Cognito User Pool               |
| `lambda_post_auth_trigger`    | The ARN of the post-authentication Lambda function, if set    |
| `account_recovery_mechanisms` | The account recovery mechanisms for the Cognito User Pool    |

## Notes

- The module uses `random_id` and `random_string` resources to ensure unique resource names.
- Resources are conditionally created based on the `enable_module` variable.
- MFA configuration requires `mfa_configuration` to be set to `ON` or `OPTIONAL` for `mfa_software_token` to take effect.
- Account recovery settings are only applied if `enable_account_recovery` is `true` and valid `account_recovery_mechanisms` are provided.
- Lambda triggers are optional and only configured if their respective ARNs are provided.

## License

This module is licensed under the MIT License.
