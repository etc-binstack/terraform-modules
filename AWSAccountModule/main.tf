# Defining AWS caller identity data source
data "aws_caller_identity" "current" {
  count = var.enable_caller_identity ? 1 : 0
}

# Defining AWS ELB service account data source
data "aws_elb_service_account" "main" {
  count = var.enable_elb_service_account ? 1 : 0
}

# Defining AWS region data source
data "aws_region" "current" {
  count = var.enable_region_info ? 1 : 0
}

# Defining AWS partition data source
data "aws_partition" "current" {
  count = var.enable_partition_info ? 1 : 0
}