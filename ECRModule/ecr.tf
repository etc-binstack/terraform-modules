resource "aws_ecr_repository" "ecr_repos" {
  for_each             = var.enable_module ? toset(var.ecr_repository_names) : toset([])
  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = lookup(var.image_scan, each.value, { enable = false }).enable
  }

  lifecycle {
    prevent_destroy = false # Optional: Prevent accidental deletion
  }

  tags = var.tags
}

## Uncomment the following block if you want to enable ECR image scanning configuration
## Note: This is commented out as per your request to not suggest deleted code.
## Uncomment if you want to enable ECR image scanning configuration
resource "aws_ecr_registry_scanning_configuration" "ecr_repos" {
  count     = var.enable_module && var.enable_global_scanning && lookup(var.image_scan, "global_scan", { enable = false }).enable ? 1 : 0
  scan_type = lookup(var.image_scan, "global_scan").scan_type

  rule {
    scan_frequency = lookup(var.image_scan, "global_scan").frequency
    repository_filter {
      filter      = "*" # Apply to all repositories
      filter_type = "WILDCARD"
    }
  }
}


resource "aws_ecr_lifecycle_policy" "ecr_repos" {
  for_each   = var.enable_module ? toset(var.ecr_repository_names) : toset([])
  repository = aws_ecr_repository.ecr_repos[each.value].name

  policy = jsonencode({
    rules = [
      for policy in var.lifecycle_policy : {
        rulePriority = policy.policy_priority
        description  = "Keep last ${policy.image_count} images for ${policy.tag_status}"
        selection = {
          tagStatus   = policy.tag_status
          countType   = "imageCountMoreThan"
          countNumber = policy.image_count
        }
        action = {
          type = "expire"
        }
      } if policy.enable
    ]
  })
}
