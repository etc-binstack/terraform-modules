# Module enablement flag
variable "enable_module" {
  description = "Whether to enable this module"
  type        = bool
  default     = false
}

# Environment configuration
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.environment))
    error_message = "Environment must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

# VPC configuration
variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

# Subnet configuration
variable "public_subnet_ids" {
  description = "List of existing public subnet IDs"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs"
  type        = list(string)
  default     = []
}

variable "isolated_subnet_ids" {
  description = "List of existing isolated subnet IDs"
  type        = list(string)
  default     = []
}

# Internet Gateway configuration
variable "internet_gateway_id" {
  description = "ID of the existing Internet Gateway (optional)"
  type        = string
  default     = null
}

variable "internet_gateway_name_tag" {
  description = "Name tag of the Internet Gateway to lookup (alternative to internet_gateway_id)"
  type        = string
  default     = null
}

# Route table configuration
variable "route_table_name_prefix" {
  description = "Prefix for route table names to lookup (will be combined with environment)"
  type        = string
  default     = ""
}

# Database subnet group configuration
variable "db_subnet_group_name" {
  description = "Name of the existing DB subnet group (optional)"
  type        = string
  default     = null
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Data source configuration
variable "lookup_nat_gateways" {
  description = "Whether to lookup NAT gateways"
  type        = bool
  default     = true
}

variable "lookup_route_tables" {
  description = "Whether to lookup route tables"
  type        = bool
  default     = true
}

variable "lookup_db_subnet_group" {
  description = "Whether to lookup DB subnet group"
  type        = bool
  default     = false
}