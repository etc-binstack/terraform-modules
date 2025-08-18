variable "enable_module" {
  description = "A flag to enable or disable the module"
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "The ID of the existing private Route 53 hosted zone"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to associate the private DNS zone with"
  type        = string
}

# variable "private_domain_name" {
#   description = "The domain name for the private DNS zone"
#   type        = string
# }