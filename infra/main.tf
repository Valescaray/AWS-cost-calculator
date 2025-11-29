provider "aws" {
  region = var.region
}

# S3 reports + hosting
module "s3" {
  source               = "./modules/s3"
  bucket_name          = var.report_bucket_name != "" ? var.report_bucket_name : "${var.project}-${var.env}-reports"
  dashboard_source_dir = "${path.module}/../dashboard"
  upload_dashboard     = true
}

# SNS topic
module "sns" {
  source                    = "./modules/sns"
  topic_name                = "${var.project}-${var.env}-alerts"
  email_subscription        = var.notification_email
  enable_email_subscription = var.notification_email != ""
}

# IAM: reference existing lambda execution role
module "iam" {
  source           = "./modules/iam"
  project          = var.project
  env              = var.env
  lambda_role_name = var.lambda_role_name
}

# Lambda: cost collector
module "lambda_collector" {
  source   = "./modules/lambda"
  name     = "${var.project}-collector"
  zip_path = var.collector_zip_path
  handler  = "app.lambda_handler"
  runtime  = "python3.11"
  role_arn = module.iam.lambda_role_arn
  environment = {
    REPORT_BUCKET   = module.s3.bucket
    SNS_TOPIC_ARN   = module.sns.topic_arn
    DAILY_THRESHOLD = "5"
  }
}

# Lambda: weekly report
module "lambda_weekly" {
  source   = "./modules/lambda"
  name     = "${var.project}-weekly"
  zip_path = var.weekly_zip_path
  handler  = "app.lambda_handler"
  runtime  = "python3.11"
  role_arn = module.iam.lambda_role_arn
  environment = {
    REPORT_BUCKET = module.s3.bucket
    SNS_TOPIC_ARN = module.sns.topic_arn
  }
}

# Lambda: telegram notifier
module "lambda_telegram" {
  source   = "./modules/lambda"
  name     = "${var.project}-telegram-notifier"
  zip_path = var.telegram_zip_path
  handler  = "app.lambda_handler"
  runtime  = "python3.11"
  role_arn = module.iam.lambda_role_arn
  timeout  = 30
  environment = {
    TG_TOKEN   = var.telegram_bot_token
    TG_CHAT_ID = var.telegram_chat_id
  }
}

# SNS subscription for Telegram Lambda
resource "aws_sns_topic_subscription" "telegram" {
  topic_arn = module.sns.topic_arn
  protocol  = "lambda"
  endpoint  = module.lambda_telegram.lambda_arn
}

# Permission for SNS to invoke Telegram Lambda
resource "aws_lambda_permission" "sns_telegram" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_telegram.lambda_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.sns.topic_arn
}

# EventBridge rules to schedule
module "eventbridge" {
  source               = "./modules/eventbridge"
  collector_lambda_arn = module.lambda_collector.lambda_arn
  weekly_lambda_arn    = module.lambda_weekly.lambda_arn
}

# AWS Budgets (demo)
module "budgets" {
  source        = "./modules/budgets"
  name          = "${var.project}-${var.env}-budget"
  budget_amount = 10
  sns_topic_arn = module.sns.topic_arn
}

# AWS Config rule: required-tags (example)
module "config_rule" {
  source        = "./modules/config_rule"
  rule_name     = "${var.project}-required-tags"
  tag_keys      = ["cost-center", "owner"]
  sns_topic_arn = module.sns.topic_arn
}


