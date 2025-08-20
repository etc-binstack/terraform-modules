variable "tags" {
  description = "A map of tags to associate with the resources"
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  type        = string
  description = "The domain name for the hosted zone"

  validation {
    condition     = length(regexall("^[a-zA-Z0-9][a-zA-Z0-9-.]{1,61}[a-zA-Z0-9](?:\\.[a-zA-Z]{2,})+$", var.domain_name)) > 0
    error_message = "The domain_name must be a valid domain name (e.g., example.com)."
  }
}

variable "enable_module" {
  description = "A flag to enable or disable the module"
  type        = bool
  default     = false
}

variable "route53_validation" {
  description = "A flag to enable or disable Route53 validation"
  type        = bool
  default     = true
}

variable "enable_sans" {
  description = "A flag to enable or disable subject alternative names"
  type        = bool
  default     = true
}

variable "subject_alternative_names" {
  description = "List of subject alternative names for the certificate"
  type        = list(string)
  default     = []
}