variable "tags" {
  description = "Tags for the repositories"
  type        = map(string)
  default     = {}
}

variable "ecr_repository_names" {
  description = "List of names for ECR repositories"
  type        = list(string)
  validation {
    condition     = var.enable_module ? length(var.ecr_repository_names) > 0 : true
    error_message = "ecr_repository_names must not be empty when enable_module is true."
  }
}

variable "enable_module" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}

## Image Lifecycle policy
variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "lifecycle_policy" {
  description = "List of lifecycle policy configurations"
  type = list(object({
    enable          = bool
    policy_priority = number
    image_count     = number
    tag_status      = string
  }))
  default = [
    {
      enable          = false
      policy_priority = 1
      image_count     = 30
      tag_status      = "any"
    }
  ]
  validation {
    condition     = alltrue([for policy in var.lifecycle_policy : policy.policy_priority > 0 && policy.policy_priority <= 10])
    error_message = "Priority must be between 1 and 10 for all policies."
  }
  validation {
    condition     = alltrue([for policy in var.lifecycle_policy : policy.image_count > 0])
    error_message = "Count number must be a positive integer for each policy."
  }
  validation {
    condition     = alltrue([for policy in var.lifecycle_policy : contains(["any", "tagged", "untagged"], policy.tag_status)])
    error_message = "Tag status must be one of 'any', 'tagged', or 'untagged' for all policies."
  }
}

## Scan ECS Images
# variable "image_scan" {
#   description = "Image scanning configuration for each repository, keyed by repository name"
#   type = map(object({
#     enable    = bool
#     scan_type = string
#     frequency = string
#   }))
#   default = {}
#   validation {
#     condition     = alltrue([for k, v in var.image_scan : contains(var.ecr_repository_names, k) || !var.enable_module])
#     error_message = "All keys in image_scan must match a repository name in ecr_repository_names when enable_module is true."
#   }
#   validation {
#     condition     = length(var.image_scan) == 0 || alltrue([for k, v in var.image_scan : contains(["BASIC", "ENHANCED"], v.scan_type)])
#     error_message = "Scan type must be either BASIC or ENHANCED."
#   }
#   validation {
#     condition     = length(var.image_scan) == 0 || alltrue([for k, v in var.image_scan : contains(["SCAN_ON_PUSH", "CONTINUOUS_SCAN"], v.frequency)])
#     error_message = "Scan frequency must be either SCAN_ON_PUSH or CONTINUOUS_SCAN."
#   }
# }

variable "image_scan" {
  description = "Image scanning configuration for each repository (keyed by repository name) or global scanning (keyed by 'global_scan')"
  type = map(object({
    enable    = bool
    scan_type = string
    frequency = string
  }))
  default = {}
  validation {
    condition     = var.enable_global_scanning ? contains(keys(var.image_scan), "global_scan") : alltrue([for k, v in var.image_scan : contains(var.ecr_repository_names, k) || !var.enable_module])
    error_message = "When enable_global_scanning is true, image_scan must contain a 'global_scan' key. Otherwise, all keys must match ecr_repository_names when enable_module is true."
  }
  validation {
    condition     = length(var.image_scan) == 0 || alltrue([for k, v in var.image_scan : contains(["BASIC", "ENHANCED"], v.scan_type)])
    error_message = "Scan type must be either BASIC or ENHANCED."
  }
  validation {
    condition     = length(var.image_scan) == 0 || alltrue([for k, v in var.image_scan : contains(["SCAN_ON_PUSH", "CONTINUOUS_SCAN"], v.frequency)])
    error_message = "Scan frequency must be either SCAN_ON_PUSH or CONTINUOUS_SCAN."
  }
}

variable "enable_global_scanning" {
  description = "Whether to enable global registry scanning (overrides per-repository scanning)"
  type        = bool
  default     = false
}
