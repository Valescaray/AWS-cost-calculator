output "config_rule_arn" {
  description = "ARN of the Config rule"
  value       = aws_config_config_rule.required_tags.arn
}

output "config_rule_id" {
  description = "ID of the Config rule"
  value       = aws_config_config_rule.required_tags.id
}

output "config_recorder_name" {
  description = "Name of the Config recorder"
  value       = aws_config_configuration_recorder.main.name
}
