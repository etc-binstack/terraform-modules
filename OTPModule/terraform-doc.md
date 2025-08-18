# Terraform OTP System Module Structure

```pgsql
terraform/
│
├── modules/
│   └── otp/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── lambda/
│       │   ├── generate-otp.py
│       │   └── verify-otp.py
│       └── policies/
│           ├── dynamodb.json
│           ├── kms.json
│           ├── ses.json
│           ├── sns.json
│           └── logs.json
│
├── environments/
│   ├── dev.tfvars
│   └── prod.tfvars
│
└── main.tf
```

## iam.tf (ild)
```yml
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:${region}:${account_id}:table/${table_name}"
        }
    ]
}
```

### kms.tf (old versions)
```yml
## File: kms.tf
##============================
## KMS Key for Primary Region
##============================

locals {
  tamplates_file = var.enable_multi_region == true ? file("${path.module}/templates/kms/mrk_policy.json.tpl") : file("${path.module}/templates/kms/policy.json.tpl")
}

resource "aws_kms_key" "primary_key" {
  count                   = var.enable_module ? 1 : 0
  description             = "KMS key for OTP encryption"
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.enable_multi_region
  deletion_window_in_days = 7
  key_usage               = "ENCRYPT_DECRYPT"

  # Temporary default policy to allow creation
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = "arn:aws:iam::${local.account_id}:root" },
      Action    = "kms:*",
      Resource  = "*"
    }]
  })

  tags = var.tags
}

data "template_file" "key_policy" {
  count    = var.enable_module ? 1 : 0
  template = local.tamplates_file //file("${path.module}/templates/kms/policy.json.tpl")

  vars = {
    region              = var.region
    account_id          = local.account_id
    lambda_role_name    = aws_iam_role.lambda_role[0].name
    kms_key_arn         = aws_kms_key.primary_key[0].arn
    replica_kms_key_arn = var.enable_module && var.enable_multi_region ? aws_kms_replica_key.replica_key[0].arn : 0
    secondary_region    = var.enable_module && var.enable_multi_region ? var.secondary_region : 0
  }
}

resource "aws_kms_key_policy" "primary_policy" {
  count  = var.enable_module ? 1 : 0
  key_id = aws_kms_key.primary_key[0].id
  policy = data.template_file.key_policy[0].rendered
}

resource "aws_kms_alias" "primary_key" {
  count         = var.enable_module ? 1 : 0
  name          = "alias/${var.kms_key_alias}-${random_id.this[0].hex}"
  target_key_id = aws_kms_key.primary_key[0].key_id
}

##============================
## KMS Key for Replica Region
##============================
resource "aws_kms_replica_key" "replica_key" {
  count                   = var.enable_module && var.enable_multi_region ? 1 : 0
  provider                = aws.replica
  description             = "KMS Replica key for OTP encryption"
  primary_key_arn         = try(aws_kms_key.primary_key[0].arn, null)
  deletion_window_in_days = 7

  tags = var.tags
}

resource "aws_kms_alias" "replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  name          = "alias/${var.kms_key_alias}-${random_id.this[0].hex}"
  target_key_id = aws_kms_replica_key.replica_key[0].key_id
}

data "template_file" "replica_key_policy" {
  count    = var.enable_module && var.enable_multi_region ? 1 : 0
  template = local.tamplates_file  //file("${path.module}/templates/kms/policy.json.tpl")

  vars = {
    region              = var.secondary_region
    account_id          = local.account_id
    lambda_role_name    = aws_iam_role.lambda_role[0].name
    kms_key_arn         = aws_kms_replica_key.replica_key[0].arn
    replica_kms_key_arn = var.enable_module && var.enable_multi_region ? aws_kms_key.primary_key[0].arn : 0
    secondary_region    = var.enable_module && var.enable_multi_region ? var.region : 0
  }
}

resource "aws_kms_key_policy" "replica_policy" {
  count    = var.enable_module && var.enable_multi_region ? 1 : 0
  provider = aws.replica
  key_id   = aws_kms_replica_key.replica_key[0].id
  policy   = data.template_file.replica_key_policy[0].rendered
}

## kms_v2.tf
##============================
## KMS Key for Primary Region
##============================

locals {
  # Fix the typo in 'tamplates_file' -> 'templates_file'
  templates_file = var.enable_multi_region == true ? file("${path.module}/templates/kms/mrk_policy.json.tpl") : file("${path.module}/templates/kms/policy.json.tpl")
}

resource "aws_kms_key" "primary_key" {
  count                   = var.enable_module ? 1 : 0
  description             = "KMS key for OTP encryption"
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.enable_multi_region
  deletion_window_in_days = 7
  key_usage               = "ENCRYPT_DECRYPT"

  # Temporary default policy to allow creation
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = "arn:aws:iam::${local.account_id}:root" },
      Action    = "kms:*",
      Resource  = "*"
    }]
  })

  tags = var.tags
}

# Use templatefile() instead of deprecated template_file data source
locals {
  primary_key_policy_vars = {
    region              = var.region
    account_id          = local.account_id
    lambda_role_name    = var.enable_module ? aws_iam_role.lambda_role[0].name : ""
    kms_key_arn         = var.enable_module ? aws_kms_key.primary_key[0].arn : ""
    replica_kms_key_arn = var.enable_module && var.enable_multi_region ? aws_kms_replica_key.replica_key[0].arn : ""
    secondary_region    = var.enable_module && var.enable_multi_region ? var.secondary_region : ""
  }
}

resource "aws_kms_key_policy" "primary_policy" {
  count  = var.enable_module ? 1 : 0
  key_id = aws_kms_key.primary_key[0].id
  policy = templatefile(
    var.enable_multi_region ? "${path.module}/templates/kms/mrk_policy.json.tpl" : "${path.module}/templates/kms/policy.json.tpl",
    local.primary_key_policy_vars
  )
  
  # Ensure the policy is applied after the key is created
  depends_on = [aws_kms_key.primary_key]
}

resource "aws_kms_alias" "primary_key" {
  count         = var.enable_module ? 1 : 0
  name          = "alias/${var.kms_key_alias}-${random_id.this[0].hex}"
  target_key_id = aws_kms_key.primary_key[0].key_id
}

##============================
## KMS Key for Replica Region
##============================
resource "aws_kms_replica_key" "replica_key" {
  count                   = var.enable_module && var.enable_multi_region ? 1 : 0
  provider                = aws.replica
  description             = "KMS Replica key for OTP encryption"
  primary_key_arn         = try(aws_kms_key.primary_key[0].arn, null)
  deletion_window_in_days = 7

  tags = var.tags
}

resource "aws_kms_alias" "replica" {
  count         = var.enable_module && var.enable_multi_region ? 1 : 0
  provider      = aws.replica
  name          = "alias/${var.kms_key_alias}-${random_id.this[0].hex}"
  target_key_id = aws_kms_replica_key.replica_key[0].key_id
}

locals {
  replica_key_policy_vars = {
    region              = var.enable_module && var.enable_multi_region ? var.secondary_region : ""
    account_id          = local.account_id
    lambda_role_name    = var.enable_module ? aws_iam_role.lambda_role[0].name : ""
    kms_key_arn         = var.enable_module && var.enable_multi_region ? aws_kms_replica_key.replica_key[0].arn : ""
    replica_kms_key_arn = var.enable_module && var.enable_multi_region ? aws_kms_key.primary_key[0].arn : ""
    secondary_region    = var.enable_module && var.enable_multi_region ? var.region : ""
  }
}

resource "aws_kms_key_policy" "replica_policy" {
  count    = var.enable_module && var.enable_multi_region ? 1 : 0
  provider = aws.replica
  key_id   = aws_kms_replica_key.replica_key[0].id
  policy = templatefile(
    var.enable_multi_region ? "${path.module}/templates/kms/mrk_policy.json.tpl" : "${path.module}/templates/kms/policy.json.tpl",
    local.replica_key_policy_vars
  )
  
  # Ensure the policy is applied after the replica key is created
  depends_on = [aws_kms_replica_key.replica_key]
}
```

### fambda_functions.tf
```yml
data "archive_file" "generate_otp_zip" {
  count         = var.enable_module ? 1 : 0  
  type        = "zip"
  source_file = "${path.module}/lambda/generate_otp.py"
  output_path = "${path.module}/lambda/generate_otp.zip"
}

data "archive_file" "verify_otp_zip" {
  count         = var.enable_module ? 1 : 0  
  type        = "zip"
  source_file = "${path.module}/templates/lambda/verify_otp.py"
  output_path = "${path.module}/templates/lambda/verify_otp.zip"
}

resource "aws_lambda_function" "generate_otp" {
  count         = var.enable_module ? 1 : 0
  filename      = data.archive_file.generate_otp_zip.output_path
  function_name = var.lambda_generate_otp_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "generate_otp.lambda_handler"
  runtime       = "python3.13"
  timeout       = 15

  environment {
    variables = {
      DYNAMODB_TABLE      = var.dynamodb_table_name
      KMS_KEY_ID          = aws_kms_key.primary_key[0].key_id
      SENDGRID_API_KEY    = var.sendgrid_api_key
      SENDGRID_FROM_EMAIL = var.email_sender
      SES_FROM_EMAIL      = var.email_sender
      OTP_EXPIRATION_TIME = 5
    }
  }
}

resource "aws_lambda_function" "verify_otp" {
  count         = var.enable_module ? 1 : 0
  filename      = data.archive_file.verify_otp_zip.output_path
  function_name = var.lambda_verify_otp_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "verify_otp.lambda_handler"
  runtime       = "python3.13"
  timeout       = 15

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      KMS_KEY_ID     = aws_kms_key.primary_key[0].key_id
    }
  }
}
```

# iam.tf 
```yml
# Role
resource "aws_iam_role" "lambda_role" {
  count = var.enable_module ? 1 : 0
  name  = var.lambda_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policies from files
locals {
  policies = fileset("${path.module}/policies", "*.json")
}

resource "aws_iam_policy" "lambda_policies" {
  count    = var.enable_module ? 1 : 0
  for_each = toset(local.policies)
  name     = replace(each.key, ".json", "")
  policy   = file("${path.module}/policies/${each.key}")
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  count    = var.enable_module ? 1 : 0
  for_each = aws_iam_policy.lambda_policies[count.index]

  policy_arn = each.value.arn
  role       = aws_iam_role.lambda_role.name
}
```


### dynamodb.tf

```yml
## File: dynamodb.tf
##============================
## DynamoDB Table - Primary Region
##============================
resource "aws_dynamodb_table" "otp_table" {
  count        = var.enable_module ? 1 : 0
  name         = var.dynamodb_table_name
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
}
```