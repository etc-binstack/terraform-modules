# Troubleshooting "No Matching Resources Found" Errors

## Common Causes

1. **Wrong AWS Region**: Resources exist in a different region than where Terraform is running
2. **Wrong AWS Account**: Resources exist in a different AWS account
3. **Incorrect Resource IDs**: The IDs provided don't match actual AWS resources
4. **AWS Profile/Credentials**: Terraform is using different credentials than expected

## Step-by-Step Troubleshooting

### 1. Verify AWS Configuration

```bash
# Check current AWS configuration
aws configure list
aws sts get-caller-identity
aws ec2 describe-regions --query 'Regions[?RegionName==`us-east-1`]'

# Check current region
aws configure get region
```

### 2. Verify Resources Exist

```bash
# Check if VPC exists
aws ec2 describe-vpcs --vpc-ids vpc-09cac06688a7c379e

# Check if subnets exist
aws ec2 describe-subnets --subnet-ids subnet-09b2be4372e880054 subnet-0c34d5e4b72e1ec18

# Check if Internet Gateway exists
aws ec2 describe-internet-gateways --internet-gateway-ids igw-06f70b7d5989259ce

# List all VPCs in current region/account
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

# List all subnets in current region/account
aws ec2 describe-subnets --query 'Subnets[*].[SubnetId,VpcId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' --output table
```

### 3. Check Terraform Provider Configuration

Make sure your Terraform provider is configured correctly:

```hcl
# In your main configuration
provider "aws" {
  region  = "us-east-1"  # Ensure this matches where your resources are
  profile = "default"    # Or your specific AWS profile
}
```

### 4. Create a Resource Discovery Script

Use this Terraform configuration to discover existing resources:

```hcl
# discovery.tf - Run this separately to find your resources
data "aws_vpcs" "all" {}

data "aws_subnets" "all" {
  for_each = toset(data.aws_vpcs.all.ids)
  filter {
    name   = "vpc-id"
    values = [each.value]
  }
}

output "discovered_vpcs" {
  value = {
    for vpc_id in data.aws_vpcs.all.ids : vpc_id => {
      subnets = data.aws_subnets.all[vpc_id].ids
    }
  }
}
```

## Quick Fixes

### Option 1: Update data.tf with Better Error Handling

```hcl
# Updated data sources with better error handling
data "aws_vpc" "this" {
  count = var.enable_module ? 1 : 0
  
  # Add filters to make the search more specific
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  # This will show more helpful error messages
  lifecycle {
    postcondition {
      condition     = self.id != ""
      error_message = "VPC with ID ${var.vpc_id} not found in region ${data.aws_region.current[0].name}"
    }
  }
}

# Make subnet lookups more defensive
data "aws_subnet" "public" {
  count = var.enable_module && length(var.public_subnet_ids) > count.index ? length(var.public_subnet_ids) : 0
  id    = var.public_subnet_ids[count.index]
  
  lifecycle {
    postcondition {
      condition     = self.id != ""
      error_message = "Public subnet with ID ${var.public_subnet_ids[count.index]} not found"
    }
  }
}
```

### Option 2: Add Validation Mode

Add a validation mode to the module:

```hcl
# Add to variables.tf
variable "validate_resources" {
  description = "Whether to validate that all resources exist before proceeding"
  type        = bool
  default     = true
}

# Add validation data sources
data "aws_vpc" "validate" {
  count = var.enable_module && var.validate_resources ? 1 : 0
  id    = var.vpc_id
}
```

## Resolution Steps

1. **First, verify your resources exist**:
   ```bash
   aws ec2 describe-vpcs --vpc-ids vpc-09cac06688a7c379e
   ```

2. **If resources don't exist, you need to**:
   - Update your configuration with correct IDs
   - Or switch to the correct AWS region/account
   - Or create the resources first

3. **If resources exist but Terraform can't find them**:
   - Check AWS credentials and region
   - Verify Terraform provider configuration

4. **Use the updated module with better error handling** (see Option 1 above)
