############################################
## VPC Peering Configuration 
############################################

provider "aws" {
  alias                    = "accepter"
  region                   = var.acceptor_region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.accepter_profile
}

data "aws_vpc" "accepter" {
  count    = var.enable_module ? 1 : 0
  provider = aws.accepter
  id       = try(var.accepter_vpc_id, null)
}

data "aws_vpc" "owner" {
  count = var.enable_module ? 1 : 0
  id    = try(var.owner_vpc_id, null)
}

locals {
  accepter_account_id = length(data.aws_vpc.accepter) > 0 ? element(split(":", data.aws_vpc.accepter[0].arn), 4) : null
}

resource "aws_vpc_peering_connection" "owner" {
  count         = var.enable_module && length(data.aws_vpc.accepter) > 0 ? 1 : 0
  vpc_id        = var.owner_vpc_id
  peer_vpc_id   = length(data.aws_vpc.accepter) > 0 ? data.aws_vpc.accepter[0].id : null
  peer_owner_id = local.accepter_account_id
  peer_region   = var.acceptor_region
  auto_accept   = var.auto_accept

  requester {
    allow_remote_vpc_dns_resolution = var.allow_owner_dns_resolution
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }

  tags = merge(
    var.tags,
    {
      Name = "peer_to_${var.accepter_profile}"
    }
  )
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  count                     = var.enable_module && length(data.aws_vpc.accepter) > 0 ? 1 : 0
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.owner[count.index].id
  auto_accept               = var.auto_accept

  accepter {
    allow_remote_vpc_dns_resolution = var.allow_accepter_dns_resolution
  }

  timeouts {
    create = "10m"
  }

  tags = merge(
    var.tags,
    {
      Name = "peer_to_${var.owner_profile}"
    }
  )
}

resource "aws_route" "owner_to_accepter" {
  count                     = var.enable_module && var.modify_owner_routetable && length(var.owner_route_table_ids) > 0 && var.accepter_cidr_block != "" ? length(var.owner_route_table_ids) : 0
  route_table_id            = var.owner_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.owner[0].id
}

resource "aws_route" "accepter_to_owner" {
  count                     = var.enable_module && var.modify_accepter_routetable && length(var.accepter_route_table_ids) > 0 && var.owner_cidr_block != "" ? length(var.accepter_route_table_ids) : 0
  provider                  = aws.accepter
  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.owner_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.owner[0].id
}