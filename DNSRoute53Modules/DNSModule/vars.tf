variable "enable_public_zone" {
  description = "Whether to create or fetch a public Route 53 hosted zone"
  type        = bool
  default     = false
}

variable "enable_private_zone" {
  description = "Whether to create or associate a private Route 53 hosted zone"
  type        = bool
  default     = false
}

variable "use_existing_public_zone" {
  description = "Whether to use an existing public Route 53 hosted zone instead of creating a new one"
  type        = bool
  default     = false
}

variable "use_existing_private_zone" {
  description = "Whether to use an existing private Route 53 hosted zone instead of creating a new one"
  type        = bool
  default     = false
}

variable "public_domain_name" {
  description = "The domain name for the public Route 53 hosted zone (used when creating a new zone)"
  type        = string
  default     = ""
}

variable "private_domain_name" {
  description = "The domain name for the private Route 53 hosted zone (used when creating a new zone)"
  type        = string
  default     = ""
}

variable "existing_public_zone_id" {
  description = "The ID of an existing public Route 53 hosted zone (used when use_existing_public_zone is true)"
  type        = string
  default     = null
}

variable "existing_private_zone_id" {
  description = "The ID of an existing private Route 53 hosted zone (used when use_existing_private_zone is true)"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "The ID of the VPC to associate with the private Route 53 hosted zone"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to associate with the resources"
  type        = map(string)
  default     = {}
}