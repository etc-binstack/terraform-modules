
## Variables: VPC Optional points
variable "enable_module" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}

variable "enable_peering_route" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}

variable "pcx_routes" {
  description = "List of routes to be added to private route tables."
  type = list(object({
    cidr_block     = string
    vpc_peering_id = string
  }))
  default = []
}

variable "vpc_flowlogs_enable" {
  description = "Whether to enable VPC flow logs (true or false)"
  type        = bool
}

variable "db_subnetgroup_enable" {
  description = "Whether to create the database subnet group (true or false)"
  type        = bool
}


## Variables: VPC Name Tags Overwrite
variable "environment" {
  description = "The environment name (e.g., 'dev', 'prod') for tag filtering and resource naming."
  type        = string
}

variable "environment_alias" {
  description = "The environment name (e.g., 'dev', 'prod') for tag filtering and resource naming."
  type        = string
  default     = "null"
}

variable "vpc_name_prefix" {
  description = "Prefix for naming resources associated with the VPC."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources created by this module."
  type        = map(string)
}


## Variables: VPC
variable "az_count" {
  description = "The number of Availability Zones (AZs) to deploy resources across."
  type        = number
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (e.g., '10.0.0.0/16')."
  type        = string
}

variable "subnet_cidr_block" {
  description = "The CIDR block size for each subnet (e.g., 8 for a /24 subnet size)."
  type        = number
}

variable "db_subnet_group_name" {
  description = "The name to assign to the database subnet group."
  type        = string
}

variable "vpc_flowlogs_name" {
  description = "The name to assign to the VPC Flow Logs log group."
  type        = string
}