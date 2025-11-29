output "bucket" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.reports.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.reports.arn
}

output "bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.reports[0].website_endpoint : null
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.reports.bucket_domain_name
}
