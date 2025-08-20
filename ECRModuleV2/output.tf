output "ecr_repository_uris" {
  description = "List of ECR repository URIs."
  value       = var.create_repositories ? aws_ecr_repository.ecr_repos[*].repository_url : data.aws_ecr_repository.ecr_repos[*].repository_url
}

output "ecr_repository_arns" {
  description = "List of ECR repository ARNs."
  value       = var.create_repositories ? aws_ecr_repository.ecr_repos[*].arn : data.aws_ecr_repository.ecr_repos[*].arn
}

output "ecr_repository_names" {
  description = "List of ECR repository names."
  value       = var.ecr_repository_names
}