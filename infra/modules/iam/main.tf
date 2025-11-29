# Reference existing Lambda execution role created via AWS Console
data "aws_iam_role" "lambda_execution" {
  name = var.lambda_role_name
}
