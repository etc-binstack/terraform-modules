variable "enable_caller_identity" {
  description = "Enable retrieval of AWS caller identity information"
  type        = bool
  default     = true
}

variable "enable_elb_service_account" {
  description = "Enable retrieval of AWS ELB service account information"
  type        = bool
  default     = true
}

variable "enable_region_info" {
  description = "Enable retrieval of AWS region information"
  type        = bool
  default     = true
}

variable "enable_partition_info" {
  description = "Enable retrieval of AWS partition information"
  type        = bool
  default     = true
}