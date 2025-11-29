resource "aws_sns_topic" "alerts" {
  name = var.topic_name

  tags = {
    Name      = var.topic_name
    ManagedBy = "Terraform"
  }
}

# Optional email subscription
resource "aws_sns_topic_subscription" "email" {
  count     = var.enable_email_subscription && var.email_subscription != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.email_subscription
}

# Policy to allow services to publish to this topic
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAWSServicesPublish"
        Effect = "Allow"
        Principal = {
          Service = [
            "budgets.amazonaws.com",
            "config.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid    = "AllowAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
