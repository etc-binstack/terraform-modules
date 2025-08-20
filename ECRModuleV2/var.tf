variable "ecr_repository_names" {
  description = "List of names for the ECR repositories to manage or fetch."
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name (e.g., dev, prod) for tagging and naming conventions."
  type        = string
  default     = "dev"
}

variable "creator" {
  description = "Name or identifier of the creator for tagging."
  type        = string
  default     = "terraform"
}

variable "project" {
  description = "Project name for tagging and naming conventions."
  type        = string
  default     = "default"
}

variable "create_repositories" {
  description = "Whether to create new ECR repositories or fetch existing ones."
  type        = bool
  default     = true
}

variable "enable_image_scanning" {
  description = "Enable image scanning on push for ECR repositories."
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy to manage image retention."
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "JSON string for the ECR lifecycle policy. Ignored if enable_lifecycle_policy is false."
  type        = string
  default     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 30 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

variable "encryption_type" {
  description = "Encryption type for ECR repositories (AES256 or KMS)."
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either 'AES256' or 'KMS'."
  }
}

variable "kms_key" {
  description = "KMS key ARN for encryption if encryption_type is KMS. Ignored if encryption_type is AES256."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}