## File: otp.tf
##============================
## Common Requiements
##============================
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

provider "aws" {
  alias                    = "replica"
  shared_credentials_files = ["~/.aws/credentials"]
  region                   = var.secondary_region
  profile                  = "website-${terraform.workspace}"
}

resource "random_id" "this" {
  count       = var.enable_module ? 1 : 0
  byte_length = 3 // ${random_id.this[count.index].hex}
}