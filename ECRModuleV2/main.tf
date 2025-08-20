# Fetch existing ECR repositories if create_repositories is false
data "aws_ecr_repository" "ecr_repos" {
  count = var.create_repositories ? 0 : length(var.ecr_repository_names)
  name  = element(var.ecr_repository_names, count.index)
}

# Create ECR repositories if create_repositories is true
resource "aws_ecr_repository" "ecr_repos" {
  count                = var.create_repositories ? length(var.ecr_repository_names) : 0
  name                 = element(var.ecr_repository_names, count.index)
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_image_scanning
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key : null
  }

  tags = merge(
    {
      Environment = var.environment
      Creator     = var.creator
      Project     = var.project
    },
    var.tags
  )
}

# Apply lifecycle policy to repositories if enabled
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  count      = var.enable_lifecycle_policy && var.create_repositories ? length(var.ecr_repository_names) : 0
  repository = aws_ecr_repository.ecr_repos[count.index].name
  policy     = var.lifecycle_policy
}