variable "topic_name" {
  type        = string
  description = "Name of the SNS topic"
}

variable "email_subscription" {
  type        = string
  description = "Email address for SNS notifications (optional)"
  default     = "chukwudum55@gmail.com"
}

variable "enable_email_subscription" {
  type        = bool
  description = "Whether to create email subscription"
  default     = true
}
