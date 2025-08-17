# AWS Cognito User Pool Terraform Module

This Terraform module provisions an AWS Cognito User Pool with comprehensive configuration options, including multi-tenant SaaS support, app clients, MFA, user groups, identity providers, resource servers, and custom domains. It is designed to be flexible, reusable, and secure, supporting both simple and complex authentication scenarios as of August 18, 2025.

## Features
- **Multi-Tenant SaaS Support**: Automatically creates a pre-token-generation Lambda to add custom attributes (e.g., `tenant_id`) to JWTs when `enable_multi_tenant_saas` is enabled. Supports external Lambda triggers for custom logic.
- **App Clients**: Configures multiple app clients with OAuth flows, scopes, and attribute permissions (`read_attributes`, `write_attributes`).
- **Custom Attributes**: Supports custom schemas (e.g., `tenant_id`, `company_id`) with validation for multi-tenant setups.
- **MFA**: Configures optional or mandatory MFA with software tokens or SMS.
- **Account Recovery**: Supports email and phone-based account recovery mechanisms.
- **Lambda Triggers**: Integrates with Lambda functions for pre-sign-up, post-confirmation, post-authentication, pre-token-generation, and custom messages.
- **User Groups**: Creates tenant-specific or role-based user groups.
- **Identity Providers**: Supports SAML and OIDC providers for federated authentication.
- **Resource Servers**: Configures OAuth 2.0 resource servers with custom scopes.
- **Custom Domain**: Sets up a custom domain for the Cognito hosted UI.
- **Security**: Enforces strong password policies and deletion protection.
- **Tagging**: Applies consistent tags to all resources.

## Requirements
- Terraform >= 1.0
- AWS Provider >= 4.0
- AWS account with permissions to create Cognito User Pools, Lambda functions, IAM roles, and related resources.
- For multi-tenant access token customization, the user pool must be on the Essentials or Plus tier.

## Usage

### Basic Configuration
Create a simple Cognito User Pool with an app client:

```hcl
module "cognito_pool" {
  source = "./path/to/module"

  enable_module     = true
  environment       = "dev"
  cognito_pool_name = "simple-app"

  app_clients = [
    {
      name                 = "web-client"
      callback_urls        = ["https://app.example.com/callback"]
      logout_urls          = ["https://app.example.com/logout"]
      allowed_oauth_flows  = ["code"]
      allowed_oauth_scopes = ["email", "openid"]
      generate_secret      = true
      read_attributes      = ["email"]
      write_attributes     = ["email"]
      access_token_validity = 1
      id_token_validity     = 1
      refresh_token_validity = 30
      token_validity_units   = "days"
    }
  ]

  sign_in_attribute       = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection     = "INACTIVE"

  tags = {
    Environment = "dev"
  }
}
```

### Multi-Tenant SaaS Configuration
Enable multi-tenant support with an auto-generated Lambda to add `tenant_id` to JWTs:

```hcl
module "cognito_pool" {
  source = "./path/to/module"

  enable_module     = true
  environment       = "prod"
  cognito_pool_name = "multi-tenant-app"
  enable_multi_tenant_saas = true
  jwt_custom_claims = ["tenant_id"]

  custom_schemas = [
    {
      name                     = "tenant_id"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = true
      min_length               = 1
      max_length               = 50
    }
  ]

  app_clients = [
    {
      name                 = "web-client"
      callback_urls        = ["https://app.example.com/callback"]
      logout_urls          = ["https://app.example.com/logout"]
      allowed_oauth_flows  = ["code"]
      allowed_oauth_scopes = ["email", "openid", "profile"]
      generate_secret      = true
      read_attributes      = ["email", "custom:tenant_id"]
      write_attributes     = ["email", "custom:tenant_id"]
      access_token_validity = 1
      id_token_validity     = 1
      refresh_token_validity = 30
      token_validity_units   = "days"
    }
  ]

  enable_user_groups = true
  user_groups        = ["tenant_123_users", "tenant_456_users"]

  tags = {
    Environment = "prod"
    Project     = "MultiTenantApp"
  }
}
```

### Advanced Configuration with MFA and SAML
Configure a user pool with MFA, SAML integration, and a custom domain:

```hcl
module "cognito_pool" {
  source = "./path/to/module"

  enable_module     = true
  environment       = "prod"
  cognito_pool_name = "advanced-app"

  # MFA configuration
  mfa_configuration  = "OPTIONAL"
  mfa_software_token = true
  enable_sms_mfa     = true
  sms_configuration  = {
    sns_caller_arn = "arn:aws:iam::123456789012:role/sns-role"
    external_id    = "cognito-sms-external-id"
  }

  # Account recovery
  enable_account_recovery = true
  account_recovery_mechanisms = [
    {
      name     = "verified_email"
      priority = 1
    }
  ]

  # SAML identity provider
  enable_identity_providers = true
  identity_providers        = [
    {
      provider_name = "SAMLProvider"
      provider_type = "SAML"
      provider_details = {
        MetadataURL = "https://saml.example.com/metadata.xml"
      }
      attribute_mapping = {
        email = "email"
        name  = "name"
      }
    }
  ]

  # Custom domain
  enable_domain = true
  domain_config = {
    domain          = "auth.example.com"
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  }

  app_clients = [
    {
      name                 = "web-client"
      callback_urls        = ["https://app.example.com/callback"]
      logout_urls          = ["https://app.example.com/logout"]
      allowed_oauth_flows  = ["code"]
      allowed_oauth_scopes = ["email", "openid", "profile"]
      generate_secret      = true
      read_attributes      = ["email"]
      write_attributes     = ["email"]
      access_token_validity = 1
      id_token_validity     = 1
      refresh_token_validity = 30
      token_validity_units   = "days"
    }
  ]

  tags = {
    Environment = "prod"
  }
}
```

## Multi-Tenant SaaS Support
When `enable_multi_tenant_saas = true`, the module:
1. Enforces a `tenant_id` attribute in `custom_schemas`.
2. Creates a pre-token-generation Lambda to add attributes from `jwt_custom_claims` (e.g., `tenant_id`) to ID and access token claims.
3. Ignores `lambda_triggers.pre_token_generation` in favor of the auto-generated Lambda.

### Auto-Generated Lambda
The module generates a Lambda function when `enable_multi_tenant_saas = true`:
```javascript
exports.handler = async (event) => {
  const claims = {};
  claims['tenant_id'] = event.request.userAttributes['custom:tenant_id'] || null;
  // Add other claims from jwt_custom_claims
  event.response = {
    claimsAndScopeOverrideDetails: {
      idTokenGeneration: {
        claimsToAddOrOverride: claims,
        claimsToSuppress: []
      },
      accessTokenGeneration: {
        claimsToAddOrOverride: claims,
        claimsToSuppress: [],
        scopesToAdd: [],
        scopesToSuppress: []
      },
      groupOverrideDetails: {
        groupsToOverride: event.request.groupConfiguration.groupsToOverride || [],
        iamRolesToOverride: event.request.groupConfiguration.iamRolesToOverride || [],
        preferredRole: event.request.groupConfiguration.preferredRole || ''
      }
    }
  };
  return event;
};
```

### Using an External Lambda
If `enable_multi_tenant_saas = false`, provide a custom Lambda ARN in `lambda_triggers.pre_token_generation`. Ensure the Lambda has permissions:
```hcl
resource "aws_lambda_permission" "allow_cognito_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "your-lambda-function"
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = module.cognito_pool.cognito_user_pool_arn
}
```

### Validating `tenant_id` in APIs
Use a Lambda authorizer in API Gateway to validate `tenant_id`:
```javascript
exports.handler = async (event) => {
  const token = event.authorizationToken;
  const decoded = /* Decode JWT using a library like jsonwebtoken */;
  const tenantId = decoded['tenant_id'];
  const expectedTenantId = /* Get from request context or database */;
  if (tenantId === expectedTenantId) {
    return generatePolicy('user', 'Allow', event.methodArn);
  }
  return generatePolicy('user', 'Deny', event.methodArn);
};

function generatePolicy(principalId, effect, resource) {
  return {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [{
        Action: 'execute-api:Invoke',
        Effect: effect,
        Resource: resource
      }]
    }
  };
}
```

## Use Cases
1. **Single-Tenant Applications**: Deploy a user pool for a single application with email sign-in, OAuth flows, and MFA.
2. **Multi-Tenant SaaS**: Manage multiple tenants in a single user pool with `tenant_id` attributes, validated via JWTs in APIs.
3. **Federated Authentication**: Integrate with SAML or OIDC providers for enterprise SSO.
4. **API Authentication**: Use resource servers with custom OAuth scopes for secure API access.
5. **Custom Workflows**: Attach Lambda triggers for custom sign-up, confirmation, or token generation logic.

## Inputs
| Name                       | Description                                                                 | Type          | Default       | Required |
|----------------------------|-----------------------------------------------------------------------------|---------------|---------------|----------|
| `enable_module`            | Whether to deploy the module                                                | `bool`        | `false`       | No       |
| `environment`              | Deployment environment (e.g., dev, prod)                                    | `string`      |               | Yes      |
| `cognito_pool_name`        | Name prefix for the Cognito user pool                                      | `string`      |               | Yes      |
| `enable_multi_tenant_saas` | Enable multi-tenant SaaS support with tenant_id and Lambda                 | `bool`        | `false`       | No       |
| `jwt_custom_claims`        | Custom attributes to add to JWTs (must include `tenant_id` if multi-tenant) | `list(string)`| `["tenant_id"]` | No       |
| `app_clients`              | List of app clients with OAuth and attribute settings                      | `list(object)`| `[]`          | No       |
| `sign_in_attribute`        | Primary sign-in attributes (e.g., email, phone_number)                     | `list(string)`| `[]`          | No       |
| `auto_verified_attributes` | Attributes to auto-verify (e.g., email, phone_number)                     | `list(string)`| `[]`          | No       |
| `deletion_protection`      | Prevents accidental deletion (`ACTIVE`, `INACTIVE`)                       | `string`      | `INACTIVE`    | No       |
| `case_sensitive_username`  | Enable case-sensitive usernames                                            | `bool`        | `false`       | No       |
| `enable_email_schema`      | Include default email schema                                               | `bool`        | `true`        | No       |
| `email_schema_constraints` | Constraints for email schema                                               | `object`      | `{...}`       | No       |
| `custom_schemas`           | Custom schemas (e.g., `tenant_id`)                                        | `list(object)`| `[]`          | No       |
| `password_policy`          | Password policy settings                                                  | `object`      | `{...}`       | No       |
| `mfa_configuration`        | MFA configuration (`OFF`, `ON`, `OPTIONAL`)                               | `string`      | `OFF`         | No       |
| `mfa_software_token`       | Enable software token MFA                                                 | `bool`        | `false`       | No       |
| `enable_sms_mfa`           | Enable SMS-based MFA                                                     | `bool`        | `false`       | No       |
| `sms_configuration`        | SMS configuration for MFA                                                 | `object`      | `null`        | No       |
| `enable_account_recovery`  | Enable account recovery settings                                          | `bool`        | `false`       | No       |
| `account_recovery_mechanisms` | Account recovery mechanisms                                           | `list(object)`| `[]`          | No       |
| `lambda_triggers`          | Lambda ARNs for Cognito triggers                                          | `object`      | `{...}`       | No       |
| `enable_user_groups`       | Create user groups                                                       | `bool`        | `false`       | No       |
| `user_groups`              | List of user group names                                                 | `list(string)`| `[]`          | No       |
| `enable_identity_providers`| Enable SAML/OIDC providers                                               | `bool`        | `false`       | No       |
| `identity_providers`       | Identity provider configurations                                          | `list(object)`| `[]`          | No       |
| `enable_resource_servers`  | Enable OAuth resource servers                                             | `bool`        | `false`       | No       |
| `resource_servers`         | Resource server configurations                                            | `list(object)`| `[]`          | No       |
| `enable_domain`            | Configure a custom domain                                                | `bool`        | `false`       | No       |
| `domain_config`            | Custom domain settings                                                   | `object`      | `null`        | No       |
| `tags`                     | Tags to apply to all resources                                           | `map(string)` | `{}`          | No       |

## Outputs
| Name                          | Description                                              |
|-------------------------------|----------------------------------------------------------|
| `cognito_user_pool_id`        | ID of the Cognito User Pool                             |
| `cognito_user_pool_name`      | Name of the Cognito User Pool                           |
| `cognito_user_pool_arn`       | ARN of the Cognito User Pool                            |
| `cognito_user_pool_client_ids`| List of app client IDs                                  |
| `cognito_user_pool_client_names`| List of app client names                             |
| `cognito_user_pool_client_secrets`| List of app client secrets (sensitive)              |
| `mfa_configuration`           | MFA configuration of the user pool                      |
| `lambda_triggers`             | Map of configured Lambda trigger ARNs                   |
| `account_recovery_mechanisms` | Account recovery mechanisms                            |
| `user_group_names`            | List of created user group names                       |
| `identity_provider_names`     | List of configured identity provider names              |
| `resource_server_identifiers` | List of resource server identifiers                     |
| `user_pool_domain`            | Custom domain for the user pool                        |
| `pre_token_lambda_arn`        | ARN of the auto-generated pre-token-generation Lambda   |

## Notes
- **Multi-Tenancy**: Requires `tenant_id` in `custom_schemas` and `jwt_custom_claims` when `enable_multi_tenant_saas = true`. The auto-generated Lambda adds claims to JWTs.
- **Lambda Permissions**: For external Lambdas, ensure `lambda:InvokeFunction` permission is granted for the user pool ARN.
- **Access Token Customization**: Requires Essentials or Plus tier for `pre_token_generation` Lambda to modify access tokens.
- **Tenant Isolation**: Enforce tenant isolation in your application or API layer (e.g., via Lambda authorizer).
- **Dynamic Blocks**: Resources like `lambda_config` and `schema` are conditionally created to optimize resource usage.

## Troubleshooting
- **Lambda Trigger Errors**: Ensure Lambda ARNs are valid and have `lambda:InvokeFunction` permissions.
- **Multi-Tenant Issues**: Verify `tenant_id` is in `custom_schemas`, `jwt_custom_claims`, and app client `read_attributes`/`write_attributes`.
- **MFA Issues**: Confirm SNS role permissions for SMS MFA.
- **Domain Errors**: Ensure the certificate ARN matches the region and domain.

# main.tf
```hcl
module "cognito_pool" {
  source = "./path/to/module"

  enable_module     = true
  environment       = "prod"
  cognito_pool_name = "multi-tenant-app"

  # Enable multi-tenant SaaS with auto-generated Lambda
  enable_multi_tenant_saas = true
  jwt_custom_claims       = ["tenant_id", "company_id"]

  # Custom schemas including tenant_id (required for multi-tenancy)
  custom_schemas = [
    {
      name                     = "tenant_id"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = true
      min_length               = 1
      max_length               = 50
    },
    {
      name                     = "company_id"
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      required                 = false
      min_length               = 1
      max_length               = 50
    }
  ]

  # App clients with OAuth and attribute permissions
  app_clients = [
    {
      name                 = "web-client"
      callback_urls        = ["https://app.example.com/callback"]
      logout_urls          = ["https://app.example.com/logout"]
      allowed_oauth_flows  = ["code"]
      allowed_oauth_scopes = ["email", "openid", "profile"]
      generate_secret      = true
      read_attributes      = ["email", "custom:tenant_id", "custom:company_id"]
      write_attributes     = ["email", "custom:tenant_id", "custom:company_id"]
      access_token_validity = 1
      id_token_validity     = 1
      refresh_token_validity = 30
      token_validity_units   = "days"
    }
  ]

  # Sign-in and verification
  sign_in_attribute       = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection     = "ACTIVE"
  case_sensitive_username  = false

  # Password policy
  password_policy = {
    minimum_length                   = 10
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # MFA configuration
  mfa_configuration     = "OPTIONAL"
  mfa_software_token    = true
  enable_sms_mfa        = true
  sms_configuration     = {
    sns_caller_arn = "arn:aws:iam::123456789012:role/sns-role"
    external_id    = "cognito-sms-external-id"
  }

  # Account recovery
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

  # Lambda triggers (pre_token_generation is ignored if enable_multi_tenant_saas = true)
  lambda_triggers = {
    pre_sign_up          = "arn:aws:lambda:us-east-1:123456789012:function:pre-sign-up"
    post_confirmation    = ""
    post_authentication  = ""
    pre_token_generation = "arn:aws:lambda:us-east-1:123456789012:function:custom-pre-token-gen"
    custom_message       = ""
  }

  # User groups for tenant-specific roles
  enable_user_groups = true
  user_groups        = ["tenant_123_users", "tenant_456_users"]

  # Identity providers (e.g., SAML)
  enable_identity_providers = true
  identity_providers        = [
    {
      provider_name = "SAMLProvider"
      provider_type = "SAML"
      provider_details = {
        MetadataURL = "https://saml.example.com/metadata.xml"
      }
      attribute_mapping = {
        email = "email"
        name  = "name"
      }
    }
  ]

  # Resource servers for OAuth scopes
  enable_resource_servers = true
  resource_servers       = [
    {
      name       = "api"
      identifier = "https://api.example.com"
      scopes     = [
        {
          scope_name        = "read"
          scope_description = "Read access to API"
        },
        {
          scope_name        = "write"
          scope_description = "Write access to API"
        }
      ]
    }
  ]

  # Custom domain
  enable_domain = true
  domain_config = {
    domain          = "auth.example.com"
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  }

  # Tags
  tags = {
    Environment = "prod"
    Project     = "MultiTenantApp"
  }
}
```