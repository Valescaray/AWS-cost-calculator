# EventBridge rule for daily cost collector
resource "aws_cloudwatch_event_rule" "collector_schedule" {
  name                = "cost-collector-daily"
  description         = "Trigger cost collector Lambda daily"
  schedule_expression = var.collector_schedule

  tags = {
    Name      = "cost-collector-daily"
    ManagedBy = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "collector" {
  rule      = aws_cloudwatch_event_rule.collector_schedule.name
  target_id = "cost-collector-lambda"
  arn       = var.collector_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge_collector" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.collector_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.collector_schedule.arn
}

# EventBridge rule for weekly report
resource "aws_cloudwatch_event_rule" "weekly_schedule" {
  name                = "cost-report-weekly"
  description         = "Trigger weekly cost report Lambda"
  schedule_expression = var.weekly_schedule

  tags = {
    Name      = "cost-report-weekly"
    ManagedBy = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "weekly" {
  rule      = aws_cloudwatch_event_rule.weekly_schedule.name
  target_id = "weekly-report-lambda"
  arn       = var.weekly_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge_weekly" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.weekly_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_schedule.arn
}
