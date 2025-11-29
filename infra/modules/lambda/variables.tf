variable "name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "zip_path" {
  type        = string
  description = "Path to the Lambda deployment package (zip file)"
}

variable "handler" {
  type        = string
  description = "Lambda function handler"
  default     = "app.lambda_handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "python3.11"
}

variable "role_arn" {
  type        = string
  description = "ARN of the IAM role for Lambda execution"
}

variable "environment" {
  type        = map(string)
  description = "Environment variables for the Lambda function"
  default     = {}
}

variable "timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 60
}

variable "memory_size" {
  type        = number
  description = "Lambda function memory size in MB"
  default     = 256
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
}
