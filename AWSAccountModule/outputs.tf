# Output for AWS account ID
output "aws_account_id" {
  description = "The AWS account ID"
  value       = var.enable_caller_identity ? data.aws_caller_identity.current[0].account_id : null
}

# Output for AWS caller ARN
output "aws_caller_arn" {
  description = "The ARN of the caller identity"
  value       = var.enable_caller_identity ? data.aws_caller_identity.current[0].arn : null
}

# Output for AWS caller user ID
output "aws_caller_user" {
  description = "The user ID of the caller"
  value       = var.enable_caller_identity ? data.aws_caller_identity.current[0].user_id : null
}

# Output for ELB service account ARN
output "elb_account_id" {
  description = "The ARN of the ELB service account"
  value       = var.enable_elb_service_account ? data.aws_elb_service_account.main[0].arn : null
}

# Output for AWS region name
output "aws_region_name" {
  description = "The name of the current AWS region"
  value       = var.enable_region_info ? data.aws_region.current[0].name : null
}

# Output for AWS region description
output "aws_region_description" {
  description = "The description of the current AWS region"
  value       = var.enable_region_info ? data.aws_region.current[0].description : null
}

# Output for AWS partition
output "aws_partition" {
  description = "The AWS partition (e.g., aws, aws-cn, aws-us-gov)"
  value       = var.enable_partition_info ? data.aws_partition.current[0].partition : null
}