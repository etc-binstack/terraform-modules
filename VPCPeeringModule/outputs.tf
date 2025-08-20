output "vpc_peering_connection_id" {
  description = "The ID of the VPC peering connection"
  value       = var.enable_module ? aws_vpc_peering_connection.owner[0].id : null
}

output "vpc_peering_connection_accepter_id" {
  description = "The ID of the VPC peering connection on the accepter side"
  value       = var.enable_module ? aws_vpc_peering_connection_accepter.accepter[0].id : null
}

output "accepter_account_id" {
  description = "The AWS account ID of the accepter VPC"
  value       = local.accepter_account_id
}

output "owner_dns_resolution_enabled" {
  description = "Whether DNS resolution is enabled for the owner VPC"
  value       = var.allow_owner_dns_resolution
}

output "accepter_dns_resolution_enabled" {
  description = "Whether DNS resolution is enabled for the accepter VPC"
  value       = var.allow_accepter_dns_resolution
}

output "owner_route_tables_updated" {
  description = "List of owner route table IDs updated with peering routes"
  value       = var.modify_owner_routetable ? var.owner_route_table_ids : []
}

output "accepter_route_tables_updated" {
  description = "List of accepter route table IDs updated with peering routes"
  value       = var.modify_accepter_routetable ? var.accepter_route_table_ids : []
}