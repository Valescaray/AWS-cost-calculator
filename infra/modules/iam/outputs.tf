output "lambda_role_arn" {
  description = "ARN of the existing Lambda execution role"
  value       = data.aws_iam_role.lambda_execution.arn
}

output "lambda_role_name" {
  description = "Name of the existing Lambda execution role"
  value       = data.aws_iam_role.lambda_execution.name
}
