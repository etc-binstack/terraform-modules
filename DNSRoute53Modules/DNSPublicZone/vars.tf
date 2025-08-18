variable "enable_module" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags for the repositories"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the hosted zone"
}
