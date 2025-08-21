variable "enable_module" {
  description = "Whether to deploy the VPC Link module or not"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment must not be empty."
  }
}

variable "vpc_link_name" {
  description = "Name for the VPC Link. If not provided, will be auto-generated using environment and vpc_endpoint_name"
  type        = string
  default     = null
}

variable "vpc_endpoint_name" {
  description = "Base name for the VPC endpoint, used in auto-generated naming"
  type        = string
  validation {
    condition     = length(var.vpc_endpoint_name) > 0
    error_message = "VPC endpoint name must not be empty."
  }
}

variable "vpclink_description" {
  description = "Description for the VPC Link"
  type        = string
  default     = "VPC Link for API Gateway to connect to private resources"
}

variable "target_arns" {
  description = "List of target ARNs (Network Load Balancers) for the VPC Link"
  type        = list(string)
  default     = null
  validation {
    condition = var.target_arns == null || length(var.target_arns) > 0
    error_message = "If target_arns is provided, at least one target ARN must be specified."
  }
  validation {
    condition = var.target_arns == null || alltrue([
      for arn in var.target_arns : can(regex("^arn:aws:elasticloadbalancing:", arn))
    ])
    error_message = "All target ARNs must be valid AWS Load Balancer ARNs."
  }
}

# Legacy support - will be deprecated in favor of target_arns
variable "backend_nlb_arn" {
  description = "(DEPRECATED) Single backend NLB ARN. Use target_arns instead for multiple targets support"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the VPC Link resource"
  type        = map(string)
  default     = {}
}

variable "use_random_suffix" {
  description = "Whether to add a random suffix to the VPC Link name for uniqueness"
  type        = bool
  default     = true
}

variable "random_suffix_length" {
  description = "Length of the random suffix when use_random_suffix is true"
  type        = number
  default     = 3
  validation {
    condition     = var.random_suffix_length >= 1 && var.random_suffix_length <= 10
    error_message = "Random suffix length must be between 1 and 10."
  }
}

variable "name_prefix" {
  description = "Optional prefix for the VPC Link name"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix for the VPC Link name"
  type        = string
  default     = ""
}
