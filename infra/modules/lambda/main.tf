# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name      = var.name
    ManagedBy = "Terraform"
  }
}

# Lambda Function
resource "aws_lambda_function" "function" {
  filename         = var.zip_path
  function_name    = var.name
  role             = var.role_arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  source_code_hash = filebase64sha256(var.zip_path)

  environment {
    variables = var.environment
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = {
    Name      = var.name
    ManagedBy = "Terraform"
  }
}
