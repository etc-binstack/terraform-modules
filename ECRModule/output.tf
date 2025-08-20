output "ecr_repository_uris" {
  value       = [for repo in aws_ecr_repository.ecr_repos : repo.repository_uri]
  description = "List of ECR repository URIs."
}

output "ecr_repository_names" {
  value       = [for repo in aws_ecr_repository.ecr_repos : repo.name]
  description = "List of ECR repository names."
}
