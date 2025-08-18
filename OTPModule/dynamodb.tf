##============================
## DynamoDB Table - Primary Region
##============================
resource "aws_dynamodb_table" "otp_table" {
  count        = var.enable_module ? 1 : 0
  name         = var.dynamodb_table_name
  deletion_protection_enabled = var.deletion_protection  
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "creation_timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "creation_timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "ttl_timestamp"
    enabled        = true
  }

  # For Global Tables, streams are automatically enabled and required
  # We conditionally set this based on whether we have replicas
  stream_enabled   = var.enable_module && var.enable_multi_region ? true : var.enable_dynamodb_stream
  stream_view_type = (var.enable_module && var.enable_multi_region) || var.enable_dynamodb_stream ? var.dynamodb_stream_view_type : null

  dynamic "replica" {
    for_each = var.enable_module && var.enable_multi_region ? [1] : []
    content {
      region_name = var.secondary_region
      kms_key_arn = var.enable_multi_region ? aws_kms_replica_key.replica_key[0].arn : null
    }
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_module ? aws_kms_key.primary_key[0].arn : null
  }

  tags = var.tags

  # Ignore changes to stream_arn as it's managed by AWS
  # For Global Tables, also ignore stream_enabled as it's automatically managed
  lifecycle {
    ignore_changes = [
      stream_arn,
      # For Global Tables, AWS manages stream_enabled - ignore changes to prevent conflicts
      stream_enabled
    ]
  }
}