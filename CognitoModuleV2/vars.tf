### VARIABLES: COGNITO USER POOL
################################

## Variables: Core Configuration
variable "enable_module" {
  description = "Whether to deploy the module"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "cognito_pool_name" {
  description = "Name prefix for the Cognito user pool"
  type        = string
}

## Variables: App Clients
variable "app_clients" {
  description = "List of app clients to create"
  type = list(object({
    name               = string
    callback_urls      = list(string)
    logout_urls        = list(string)
    allowed_oauth_flows = list(string)
    allowed_oauth_scopes = list(string)
    generate_secret    = bool
    read_attributes    = list(string)
    write_attributes   = list(string)
    access_token_validity = number
    id_token_validity     = number
    refresh_token_validity = number
    token_validity_units   = string
  }))
  default = []
}

## Variables: Multi-Tenant SaaS
variable "enable_multi_tenant_saas" {
  description = "Enable multi-tenant SaaS support with tenant_id attribute and pre-token-generation Lambda"
  type        = bool
  default     = false
}

variable "jwt_custom_claims" {
  description = "List of custom attributes (e.g., 'tenant_id') to add as claims to ID and access tokens"
  type        = list(string)
  default     = ["tenant_id"]
  validation {
    condition     = var.enable_multi_tenant_saas ? contains(var.jwt_custom_claims, "tenant_id") : true
    error_message = "When enable_multi_tenant_saas is true, jwt_custom_claims must include 'tenant_id'."
  }
}

## Variables: Sign-in and Verification
variable "sign_in_attribute" {
  description = "Primary sign-in attribute (email or phone_number)"
  type        = list(string)
  default     = []
}

variable "auto_verified_attributes" {
  description = "Attributes to be auto-verified (email, phone_number)"
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "When active, DeletionProtection prevents accidental deletion of user pool. Valid values are `ACTIVE` and `INACTIVE`."
  type        = string
  default     = "INACTIVE"
  validation {
    condition     = contains(["ACTIVE", "INACTIVE"], var.deletion_protection)
    error_message = "deletion_protection must be either 'ACTIVE' or 'INACTIVE'."
  }
}

variable "case_sensitive_username" {
  description = "Whether username case sensitivity will be applied"
  type        = bool
  default     = false
}

## Variables: Email Schema
variable "enable_email_schema" {
  description = "Whether to include the default email schema"
  type        = bool
  default     = true
}

variable "email_schema_constraints" {
  description = "Constraints for the email schema"
  type = object({
    min_length = number
    max_length = number
    required   = bool
    mutable    = bool
  })
  default = {
    min_length = 1
    max_length = 2048
    required   = false
    mutable    = false
  }
}

## Variables: Custom Attributes
variable "custom_schemas" {
  description = "List of custom schemas to add to the Cognito User Pool"
  type = list(object({
    name                     = string
    attribute_data_type      = string
    developer_only_attribute = bool
    mutable                  = bool
    required                 = bool
    min_length               = number
    max_length               = number
  }))
  default = []
  validation {
    condition     = var.enable_multi_tenant_saas ? length([for s in var.custom_schemas : s.name if s.name == "tenant_id"]) > 0 : true
    error_message = "When enable_multi_tenant_saas is true, custom_schemas must include a tenant_id attribute."
  }
}

## Variables: Password Policy
variable "password_policy" {
  description = "Password policy for the Cognito user pool"
  type = object({
    minimum_length                   = number
    require_lowercase                = bool
    require_numbers                  = bool
    require_symbols                  = bool
    require_uppercase                = bool
    temporary_password_validity_days = number
  })
  default = {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
}

## Variables: MFA
variable "mfa_configuration" {
  description = "MFA configuration (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OFF"
  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be 'OFF', 'ON', or 'OPTIONAL'."
  }
}

variable "mfa_software_token" {
  description = "Enable software token for MFA"
  type        = bool
  default     = false
}

variable "enable_sms_mfa" {
  description = "Enable SMS-based MFA"
  type        = bool
  default     = false
}

variable "sms_configuration" {
  description = "SMS configuration for MFA"
  type = object({
    sns_caller_arn = string
    external_id    = string
  })
  default = null
}

## Variables: Account Recovery
variable "enable_account_recovery" {
  description = "Whether to enable account recovery settings"
  type        = bool
  default     = false
}

variable "account_recovery_mechanisms" {
  description = "List of recovery mechanisms with their priorities"
  type = list(object({
    name     = string
    priority = number
  }))
  default = []
}

## Variables: Lambda Triggers
variable "lambda_triggers" {
  description = "Map of Lambda ARNs for Cognito triggers (pre_token_generation ARN is ignored if enable_multi_tenant_saas is true)"
  type = object({
    pre_sign_up           = string
    post_confirmation     = string
    post_authentication   = string
    pre_token_generation  = string
    custom_message        = string
  })
  default = {
    pre_sign_up           = ""
    post_confirmation     = ""
    post_authentication   = ""
    pre_token_generation  = ""
    custom_message        = ""
  }
}

## Variables: User Groups
variable "enable_user_groups" {
  description = "Whether to create user groups"
  type        = bool
  default     = false
}

variable "user_groups" {
  description = "List of user groups to create"
  type        = list(string)
  default     = []
}

## Variables: Identity Providers
variable "enable_identity_providers" {
  description = "Whether to enable identity providers (SAML, OIDC)"
  type        = bool
  default     = false
}

variable "identity_providers" {
  description = "List of identity providers to configure"
  type = list(object({
    provider_name = string
    provider_type = string
    provider_details = map(string)
    attribute_mapping = map(string)
  }))
  default = []
}

## Variables: Resource Servers
variable "enable_resource_servers" {
  description = "Whether to enable resource servers for OAuth 2.0"
  type        = bool
  default     = false
}

variable "resource_servers" {
  description = "List of resource servers to configure"
  type = list(object({
    name        = string
    identifier  = string
    scopes      = list(object({
      scope_name        = string
      scope_description = string
    }))
  }))
  default = []
}

## Variables: Domain Configuration
variable "enable_domain" {
  description = "Whether to configure a custom domain for the user pool"
  type        = bool
  default     = false
}

variable "domain_config" {
  description = "Domain configuration for the user pool"
  type = object({
    domain          = string
    certificate_arn = string
  })
  default = null
}

## Variables: Tagging
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}