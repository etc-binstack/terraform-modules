## Variables: VPC peer enabled/disabled
variable "enable_module" {
  description = "Whether to deploy the VPC peering module"
  type        = bool
  default     = false
}

## Variables: VPC Peering variables
variable "owner_profile" {
  description = "AWS Profile for the owner account"
  type        = string
  validation {
    condition     = length(var.owner_profile) > 0
    error_message = "The owner_profile must not be empty."
  }
}

variable "owner_vpc_id" {
  description = "The VPC ID of the owner account"
  type        = string
  validation {
    condition     = length(var.owner_vpc_id) > 0
    error_message = "The owner_vpc_id must not be empty."
  }
}

variable "accepter_profile" {
  description = "AWS Profile for the accepter account"
  type        = string
  validation {
    condition     = length(var.accepter_profile) > 0
    error_message = "The accepter_profile must not be empty."
  }
}

variable "acceptor_region" {
  description = "The AWS region of the acceptor VPC"
  type        = string
  validation {
    condition     = length(var.acceptor_region) > 0
    error_message = "The acceptor_region must not be empty."
  }
}

variable "accepter_vpc_id" {
  description = "The VPC ID of the accepter account"
  type        = string
  validation {
    condition     = length(var.accepter_vpc_id) > 0
    error_message = "The accepter_vpc_id must not be empty."
  }
}

variable "auto_accept" {
  description = "Automatically accept the peering connection"
  type        = bool
  default     = false
}

variable "modify_accepter_routetable" {
  description = "Add/Update route entry to accepter route table"
  type        = bool
  default     = false
}

variable "modify_owner_routetable" {
  description = "Add/Update route entry to owner route table"
  type        = bool
  default     = false
}

variable "owner_route_table_ids" {
  description = "List of owner route table IDs to update with peering routes"
  type        = list(string)
  default     = []
}

variable "accepter_route_table_ids" {
  description = "List of accepter route table IDs to update with peering routes"
  type        = list(string)
  default     = []
}

variable "owner_cidr_block" {
  description = "CIDR block of the owner VPC for route table entries"
  type        = string
  default     = ""
  validation {
    condition     = var.owner_cidr_block == "" || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.owner_cidr_block))
    error_message = "The owner_cidr_block must be a valid CIDR notation (e.g., 10.0.0.0/16) or empty."
  }
}

variable "accepter_cidr_block" {
  description = "CIDR block of the accepter VPC for route table entries"
  type        = string
  default     = ""
  validation {
    condition     = var.accepter_cidr_block == "" || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.accepter_cidr_block))
    error_message = "The accepter_cidr_block must be a valid CIDR notation (e.g., 10.0.0.0/16) or empty."
  }
}

variable "allow_owner_dns_resolution" {
  description = "Allow DNS resolution from accepter VPC to owner VPC"
  type        = bool
  default     = false
}

variable "allow_accepter_dns_resolution" {
  description = "Allow DNS resolution from owner VPC to accepter VPC"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Custom tags to apply to all resources"
  type        = map(string)
  default     = {}
}