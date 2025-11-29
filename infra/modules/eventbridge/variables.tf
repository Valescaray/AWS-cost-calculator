variable "collector_lambda_arn" {
  type        = string
  description = "ARN of the cost collector Lambda function"
}

variable "weekly_lambda_arn" {
  type        = string
  description = "ARN of the weekly report Lambda function"
}

variable "collector_schedule" {
  type        = string
  description = "Schedule expression for cost collector (cron or rate)"
  default     = "cron(0 9 * * ? *)" # Daily at 9 AM UTC
}

variable "weekly_schedule" {
  type        = string
  description = "Schedule expression for weekly report (cron or rate)"
  default     = "cron(0 10 ? * MON *)" # Every Monday at 10 AM UTC
}
