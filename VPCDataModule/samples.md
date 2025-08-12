# Example: Basic usage
```yml
module "existing_vpc" {
  source = "./modules/vpc-existing"

  environment = "dev"
  vpc_id      = "vpc-09cac06688a7c379e"
  
  public_subnet_ids   = ["subnet-09b2be4372e880054", "subnet-0c34d5e4b72e1ec18"]
  private_subnet_ids  = ["subnet-06655ef8f5c479a7e", "subnet-029f142c4068f8470"]
  isolated_subnet_ids = ["subnet-077a3405ca4112ad4", "subnet-02d1da3f757578709"]
  
  internet_gateway_id = "igw-06f70b7d5989259ce"
  
  lookup_nat_gateways     = true
  lookup_route_tables     = true
  lookup_db_subnet_group  = false
  
  additional_tags = {
    Project = "MyProject"
    Owner   = "DevOps Team"
  }
}
```

# Example: With configuration map (similar to your original approach)
```yml
locals {
  vpc_configs = {
    dev = {
      vpc_id              = "vpc-09cac06688a7c379e"
      public_subnet_ids   = ["subnet-09b2be4372e880054", "subnet-0c34d5e4b72e1ec18"]
      private_subnet_ids  = ["subnet-06655ef8f5c479a7e", "subnet-029f142c4068f8470"]
      isolated_subnet_ids = ["subnet-077a3405ca4112ad4", "subnet-02d1da3f757578709"]
      internet_gateway_id = "igw-06f70b7d5989259ce"
      db_subnet_group_name = null
    }
    prod = {
      vpc_id              = "vpc-prod123456789"
      public_subnet_ids   = ["subnet-prod1", "subnet-prod2"]
      private_subnet_ids  = ["subnet-prod3", "subnet-prod4"]
      isolated_subnet_ids = ["subnet-prod5", "subnet-prod6"]
      internet_gateway_id = "igw-prod123456789"
      db_subnet_group_name = "prod-demoproject-subnetgroup"
    }
  }
  
  current_config = local.vpc_configs[var.environment]
}

module "existing_vpc_with_config" {
  source = "./modules/vpc-existing"

  environment = var.environment
  vpc_id      = local.current_config.vpc_id
  
  public_subnet_ids   = local.current_config.public_subnet_ids
  private_subnet_ids  = local.current_config.private_subnet_ids
  isolated_subnet_ids = local.current_config.isolated_subnet_ids
  
  internet_gateway_id     = local.current_config.internet_gateway_id
  db_subnet_group_name    = local.current_config.db_subnet_group_name
  
  lookup_nat_gateways    = true
  lookup_route_tables    = true
  lookup_db_subnet_group = local.current_config.db_subnet_group_name != null
}
```

# Example: Using internet gateway name tag instead of ID
```yml
module "existing_vpc_with_igw_name" {
  source = "./modules/vpc-existing"

  environment = "staging"
  vpc_id      = "vpc-staging123456789"
  
  public_subnet_ids   = ["subnet-staging1", "subnet-staging2"]
  private_subnet_ids  = ["subnet-staging3", "subnet-staging4"]
  
  # Use name tag instead of ID
  internet_gateway_name_tag = "staging-demoproject-igw"
  
  route_table_name_prefix = "demoproject"  # This will look for staging-demoproject-pub-rtb, etc.
}
```
# Example: Minimal configuration (only required variables)
```yml
module "minimal_existing_vpc" {
  source = "./modules/vpc-existing"

  environment = "test"
  vpc_id      = "vpc-test123456789"
  
  # Optional: disable lookups to improve performance if not needed
  lookup_nat_gateways    = false
  lookup_route_tables    = false
  lookup_db_subnet_group = false
}
```