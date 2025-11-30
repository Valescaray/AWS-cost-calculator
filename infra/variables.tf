variable "project" {
  type    = string
  default = "cloud-cost-calculator"
}

variable "env" {
  type    = string
  default = "staging"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

# paths to zip artifacts created by the CI
variable "collector_zip_path" {
  type    = string
  default = "artifacts/collector.zip"
}


variable "weekly_zip_path" {
  type    = string
  default = "artifacts/weekly_report.zip"
}

variable "telegram_zip_path" {
  type    = string
  default = "artifacts/telegram_notifier.zip"
}

variable "report_bucket_name" {
  type    = string
  default = ""
}

variable "notification_email" {
  type    = string
  default = ""
}

variable "lambda_role_name" {
  type        = string
  description = "Name of the existing Lambda execution role created via AWS Console"
  default     = "cost-calculator-lambda-role"
}

variable "telegram_bot_token" {
  type        = string
  description = "Telegram bot token for notifications"
  sensitive   = true
  default     = ""
}

variable "telegram_chat_id" {
  type        = string
  description = "Telegram chat ID for notifications"
  sensitive   = true
  default     = ""
}

