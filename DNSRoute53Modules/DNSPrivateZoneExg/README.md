## main.tf 

```yml
## AWS Route53 (Private DNS resource)
module "private_zone" {
  source = "../../AWSModules/DNSPrivateZone"

  enable_module       = var.enable_private_dns
  private_domain_name = var.private_domain_name
  vpc_id              = var.enable_private_dns ? local.vpc.vpc_id : null

  tags = {
    Name        = "${var.environment}-${var.project}-private-dns"
    environment = var.environment
    creator     = var.creator
    project     = var.project
  }
  depends_on = [local.vpc]
}

module "existing_private_zone" {
  source = "../../AWSModules/DNSPrivateZoneExg"

  enable_module = var.enable_existing_private_dns
  vpc_id        = var.enable_existing_private_dns ? local.vpc.vpc_id : null
  zone_id       = var.enable_existing_private_dns && var.environment != "prod" ? (var.environment == "dev" ? "Z010907913B7CYPF5JF9" : (var.environment == "uat" ? "XXXXXX" : null )) : null
  depends_on    = [local.vpc]
}

locals {
  private_zone = {
    private_zone_id = var.enable_private_dns ? module.private_zone.private_zone_id : (
      var.enable_existing_private_dns ? module.existing_private_zone.private_zone_id : null
    )
    private_domain_name = var.enable_private_dns ? module.private_zone.private_domain_name : (
      var.enable_existing_private_dns ? module.existing_private_zone.private_domain_name : null
    )
    vpc_id = var.enable_private_dns || var.enable_existing_private_dns ? local.vpc.vpc_id : null
  }
}
```