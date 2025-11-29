variable "rule_name" {
  type        = string
  description = "Name of the Config rule"
}

variable "tag_keys" {
  type        = list(string)
  description = "List of required tag keys to check for compliance"
  default     = ["cost-center", "owner"]
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of SNS topic for compliance notifications"
}
