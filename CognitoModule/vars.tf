### VARIABLES: COGNITO USER POOL  
################################

## variables: Env Basic
variable "enable_module" {
  description = "Whether to deploy the module or not"
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

variable "app_client_name" {
  description = "Prefix for the app client name"
  type        = string
}

############ sign-in (optional) ###############
variable "sign_in_attribute" {
  description = "Primary sign-in attribute (email or phone_number)"
  type        = list(string)
  default     = []
}

variable "auto_verified_attributes" {
  description = "The attributes to be auto-verified. Possible values: email, phone_number"
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "When active, DeletionProtection prevents accidental deletion of user pool. Valid values are `ACTIVE` and `INACTIVE`."
  type        = string
  default     = "INACTIVE"
}

variable "case_sensitive_username" {
  description = "The Username Configuration. Setting `case_sensitive` specifies whether username case sensitivity will be applied for all users in the user pool through Cognito APIs"
  type        = bool
  default     = false
}

############ Custom attributes: schema ################
variable "custom_schemas" {
  description = "List of custom schemas to add to the Cognito User Pool"
  type        = list(object({
    name                     = string
    attribute_data_type      = string
    developer_only_attribute = bool
    mutable                  = bool
    required                 = bool
    min_length               = number
    max_length               = number
  }))
  default = []
}

############ password_policy ###############
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
  default = null
}

############ MFA ###############
variable "mfa_configuration" {
  description = "Enable Multi-Factor Authentication (MFA)"
  type        = string
  default     = "OFF"
}

variable "mfa_software_token" {
  description = "Enable software token for MFA"
  type        = bool
  default     = false
}

############ Account Recovery ###############
variable "enable_account_recovery" {
  description = "Whether to enable account recovery settings"
  type        = bool
  default     = false
}

variable "account_recovery_mechanisms" {
  description = "List of recovery mechanisms with their priorities. Each item should contain a name (email or phone_number) and priority."
  type = list(object({
    name     = string
    priority = number
  }))
  default = []
}

############ Post Config (Lambda) ###############
variable "lambda_post_auth" {
  description = "Lambda ARN for post authentication trigger"
  type        = string
  default     = "" # Default to an empty string, meaning no post-auth trigger is set.
}

variable "lambda_pre_token_generation" {
  description = "The ARN of the Lambda function to trigger before token generation."
  type        = string
  default     = "" # Default value to an empty string, meaning no Lambda trigger by default.
}
