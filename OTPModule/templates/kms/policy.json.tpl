{
  "Version": "2012-10-17",
  "Id": "key-policy",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "${kms_key_arn}"
    },
    {
      "Sid": "Allow DynamoDB to Use KMS",
      "Effect": "Allow",
      "Principal": {
        "Service": "dynamodb.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "${kms_key_arn}",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${account_id}"
        },
        "StringLike": {
          "kms:ViaService": "dynamodb.${region}.amazonaws.com"
        }
      }
    },
    {
      "Sid": "Allow Lambda Function to Use KMS",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${account_id}:role/${lambda_role_name}"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "${kms_key_arn}"
    }
  ]
}
