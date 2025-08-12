

# Whether to deploy the module or not
variable "enable_module" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}

############################################
## Variables: VPC Configuration
############################################
## Variables: VPC Name Tags Overwrite
variable "environment" {
  description = "The environment name (e.g., 'dev', 'prod') for tag filtering and resource naming."
  type        = string
}

# The number of Availability Zones (AZs) to deploy resources across
variable "az_count" {
  description = "The number of Availability Zones (AZs) to deploy resources across."
  type        = number
}

############################################
## Variables: VPC ID and Subnets Configuration
############################################

# The ID of the existing VPC
variable "existing_vpc_id" {
  description = "The ID of the existing VPC"
  type        = string
}

# List of existing public subnet IDs
variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs"
  type        = list(string)
}

# List of existing private subnet IDs
variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs"
  type        = list(string)
}

# List of existing isolated subnet IDs
variable "existing_isolated_subnet_ids" {
  description = "List of existing isolated subnet IDs"
  type        = list(string)
}

# The ID of the existing Internet Gateway
variable "existing_igw_id" {
  description = "The ID of the existing Internet Gateway"
  type        = string
}

variable "existing_vpc_tagname" {
  description = "The TagName of the existing VPCs"
  type        = string
}

########################################
## Variables: DB Subnet Group & Flow Logs
## The name to assign to the database subnet group
########################################
variable "db_subnet_group_name" {
  description = "The name to assign to the database subnet group."
  type        = string
  default     = null
}
