variable "name" {
  type        = string
  description = "Name of the budget"
}

variable "budget_amount" {
  type        = number
  description = "Monthly budget amount in USD"
  default     = 10
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of SNS topic for budget notifications"
}

variable "notification_thresholds" {
  type        = list(number)
  description = "List of threshold percentages for notifications"
  default     = [80, 100, 120]
}
