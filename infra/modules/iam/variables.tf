variable "project" {
  type        = string
  description = "Project name for resource naming"
}

variable "env" {
  type        = string
  description = "Environment (staging, production, etc.)"
}

variable "lambda_role_name" {
  type        = string
  description = "Name of the existing Lambda execution role created via AWS Console"
  default     = "cost-calculator-lambda-role"
}
