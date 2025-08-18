variable "tags" {
  description = "A map of tags to associate with the resources"
  type        = map(string)
  default     = {}
}

variable "private_domain_name" {
  description = "The private domain name to associate with the VPC"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "enable_module" {
  description = "A flag to enable or disable the module"
  type        = bool
  default     = false
}
