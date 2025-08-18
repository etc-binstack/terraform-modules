## File: vars.tf
##============================
## Variable definitions
##============================
variable "enable_module" {
  description = "Toggle to enable or disable the entire OTP module"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "Primary AWS region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region for DR"
  type        = string
}

variable "lambda_role_name" {
  description = "Name for the Lambda IAM role"
  type        = string
}

variable "sendgrid_api_key" {
  description = "SendGrid API key for email delivery"
  type        = string
  sensitive   = true
}

variable "email_sender" {
  description = "Email address used as sender for OTP emails"
  type        = string
}

variable "lambda_generate_otp_name" {
  description = "Name for the generate OTP Lambda function"
  type        = string
}

variable "lambda_verify_otp_name" {
  description = "Name for the verify OTP Lambda function"
  type        = string
}

variable "kms_key_alias" {
  description = "Alias for the KMS key"
  type        = string
}

variable "enable_multi_region" {
  description = "Toggle to enable multi-region active/active DR setup"
  type        = bool
  default     = false
}

variable "enable_key_rotation" {
  description = "Toggle to enable KMS key rotation"
  type        = bool
  default     = true
}

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB table"
  type        = string
}

variable "api_gateway_name" {
  description = "Name for the API Gateway"
  type        = string
}

# DynamoDB Stream Configuration
variable "enable_dynamodb_stream" {
  description = "Enable DynamoDB streams"
  type        = bool
  default     = false
}

variable "dynamodb_stream_view_type" {
  description = "View type for DynamoDB stream"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
  validation {
    condition = contains([
      "KEYS_ONLY",
      "NEW_IMAGE",
      "OLD_IMAGE",
      "NEW_AND_OLD_IMAGES"
    ], var.dynamodb_stream_view_type)
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}

variable "deletion_protection" {
  description = "Enable/Disable deletion protection on DynamoDB table"
  type        = bool
  default     = false
}