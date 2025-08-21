variable "enable_module" {
  description = "Whether to deploy the module or not"
  type        = bool
  default     = false
}
variable "environment" {}
variable "tags" {}
variable "vpc_endpoint_name" {}
variable "vpclink_description" {}
variable "backend_nlb_arn" {}