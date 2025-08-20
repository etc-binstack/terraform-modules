variable "enable_module" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}

variable "environment" {
  description = "The environment for the infrastructure (e.g., dev, prod, test)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "test", "staging"], var.environment)
    error_message = "Environment must be one of: dev, prod, test, staging"
  }
}

variable "name_prefix" {
  description = "Prefix to be used for naming resources in the infrastructure"
  type        = string
  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 50
    error_message = "Name prefix must be non-empty and up to 50 characters"
  }
}

variable "enable_cloudwatch_logging" {
  description = "Whether to enable CloudWatch logging for API Gateway"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}