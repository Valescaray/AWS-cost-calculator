# S3 Outputs
output "s3_bucket" {
  description = "Name of the S3 bucket for reports"
  value       = module.s3.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

output "s3_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = module.s3.bucket_website_endpoint
}

# SNS Outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.sns.topic_arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = module.sns.topic_name
}

# Lambda Outputs
output "collector_lambda_arn" {
  description = "ARN of the cost collector Lambda"
  value       = module.lambda_collector.lambda_arn
}

output "collector_lambda_name" {
  description = "Name of the cost collector Lambda"
  value       = module.lambda_collector.lambda_name
}

output "weekly_lambda_arn" {
  description = "ARN of the weekly report Lambda"
  value       = module.lambda_weekly.lambda_arn
}

output "weekly_lambda_name" {
  description = "Name of the weekly report Lambda"
  value       = module.lambda_weekly.lambda_name
}

output "telegram_lambda_arn" {
  description = "ARN of the Telegram notifier Lambda"
  value       = module.lambda_telegram.lambda_arn
}

output "telegram_lambda_name" {
  description = "Name of the Telegram notifier Lambda"
  value       = module.lambda_telegram.lambda_name
}

# IAM Outputs
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.iam.lambda_role_arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = module.iam.lambda_role_name
}

# EventBridge Outputs
output "collector_schedule_rule_arn" {
  description = "ARN of the collector EventBridge rule"
  value       = module.eventbridge.collector_rule_arn
}

output "weekly_schedule_rule_arn" {
  description = "ARN of the weekly report EventBridge rule"
  value       = module.eventbridge.weekly_rule_arn
}

# Budget Outputs
output "budget_name" {
  description = "Name of the AWS Budget"
  value       = module.budgets.budget_name
}

# Config Outputs
output "config_rule_arn" {
  description = "ARN of the Config rule"
  value       = module.config_rule.config_rule_arn
}

