resource "aws_s3_bucket" "reports" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = "cost-reporting"
    ManagedBy   = "Terraform"
  }
}

data "aws_region" "current" {}

resource "aws_s3_bucket_versioning" "reports" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "reports" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.reports.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "reports" {
  bucket = aws_s3_bucket.reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.reports.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.reports]
}

resource "aws_s3_bucket_lifecycle_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    id     = "delete-old-reports"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Upload dashboard files to S3
locals {
  dashboard_files = var.upload_dashboard ? setsubtract(fileset(var.dashboard_source_dir, "**/*"), ["config.js"]) : []
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
  }
}

resource "aws_s3_object" "dashboard_files" {
  for_each = toset(local.dashboard_files)

  bucket       = aws_s3_bucket.reports.id
  key          = "dashboard/${each.value}"
  source       = "${var.dashboard_source_dir}/${each.value}"
  etag         = filemd5("${var.dashboard_source_dir}/${each.value}")
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")

  tags = {
    Name      = "dashboard-${each.value}"
    ManagedBy = "Terraform"
  }
}

# Generate and upload config.js with dynamic values
resource "aws_s3_object" "config_js" {
  count = var.upload_dashboard ? 1 : 0

  bucket       = aws_s3_bucket.reports.id
  key          = "dashboard/config.js"
  content      = <<EOF
const CONFIG = {
    dataUrl: "https://${var.bucket_name}.s3.${data.aws_region.current.name}.amazonaws.com/reports/daily/daily.json",
    dateFormat: 'en-US',
    currency: 'USD'
};
EOF
  content_type = "application/javascript"

  tags = {
    Name      = "dashboard-config.js"
    ManagedBy = "Terraform"
  }
}

# Create placeholder folders for reports
resource "aws_s3_object" "reports_daily_folder" {
  bucket       = aws_s3_bucket.reports.id
  key          = "reports/daily/.gitkeep"
  content      = "# Daily cost reports will be stored here by Lambda"
  content_type = "text/plain"

  tags = {
    Name      = "reports-daily-folder"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_object" "reports_weekly_folder" {
  bucket       = aws_s3_bucket.reports.id
  key          = "reports/weekly/.gitkeep"
  content      = "# Weekly cost reports will be stored here by Lambda"
  content_type = "text/plain"

  tags = {
    Name      = "reports-weekly-folder"
    ManagedBy = "Terraform"
  }
}
