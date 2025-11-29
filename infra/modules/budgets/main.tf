resource "aws_budgets_budget" "monthly_cost" {
  name              = var.name
  budget_type       = "COST"
  limit_amount      = tostring(var.budget_amount)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2025-01-01_00:00"

  # Notification for actual costs
  dynamic "notification" {
    for_each = var.notification_thresholds
    content {
      comparison_operator       = "GREATER_THAN"
      threshold                 = notification.value
      threshold_type            = "PERCENTAGE"
      notification_type         = "ACTUAL"
      subscriber_sns_topic_arns = [var.sns_topic_arn]
    }
  }

  # Notification for forecasted costs
  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [var.sns_topic_arn]
  }

  tags = {
    Name      = var.name
    ManagedBy = "Terraform"
  }
}
