output "collector_rule_arn" {
  description = "ARN of the collector EventBridge rule"
  value       = aws_cloudwatch_event_rule.collector_schedule.arn
}

output "weekly_rule_arn" {
  description = "ARN of the weekly report EventBridge rule"
  value       = aws_cloudwatch_event_rule.weekly_schedule.arn
}
