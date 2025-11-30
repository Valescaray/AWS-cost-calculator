# AWS Config Recorder (required for Config Rules)
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.rule_name}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

# IAM role for AWS Config
resource "aws_iam_role" "config" {
  name = "${var.rule_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.rule_name}-config-role"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole" 
}

# S3 bucket for Config (required)
resource "aws_s3_bucket" "config" {
  bucket = "${var.rule_name}-config-bucket"

  tags = {
    Name      = "${var.rule_name}-config-bucket"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for AWS Config
resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketPutObject"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Delivery channel for Config
resource "aws_config_delivery_channel" "main" {
  name           = "${var.rule_name}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config.bucket
  sns_topic_arn  = var.sns_topic_arn

  depends_on = [aws_config_configuration_recorder.main]
}

# Start the recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# Config Rule: Required Tags
locals {
  tag_parameters = {
    for idx in range(length(var.tag_keys)) :
    "tag${idx + 1}Key" => var.tag_keys[idx]
  }
}

resource "aws_config_config_rule" "required_tags" {
  name = var.rule_name

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode(local.tag_parameters)
 
}
# resource "aws_config_config_rule" "required_tags" {
#   name = var.rule_name

#   source {
#     owner             = "AWS"
#     source_identifier = "REQUIRED_TAGS"
#   }

#   input_parameters = jsonencode({
#     tag1Key = var.tag_keys[0]
#     tag2Key = length(var.tag_keys) > 1 ? var.tag_keys[1] : null
#     tag3Key = length(var.tag_keys) > 2 ? var.tag_keys[2] : null
#     tag4Key = length(var.tag_keys) > 3 ? var.tag_keys[3] : null
#     tag5Key = length(var.tag_keys) > 4 ? var.tag_keys[4] : null
#     tag6Key = length(var.tag_keys) > 5 ? var.tag_keys[5] : null
#   })

#   depends_on = [aws_config_configuration_recorder.main]

#   tags = {
#     Name      = var.rule_name
#     ManagedBy = "Terraform"
#   }
# }
