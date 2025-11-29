# AWS Cost Calculator

Production-ready AWS cost monitoring infrastructure with automated reporting and alerting.

## Features

- **Daily Cost Collection**: Automatically fetches AWS cost data using Cost Explorer API
- **Spike Detection**: Alerts when daily costs exceed configurable thresholds
- **Weekly Reports**: Generates CSV and HTML reports with 30-day cost aggregation
- **Multi-Channel Alerts**: Email, Slack (via AWS Chatbot), and Telegram notifications
- **Budget Monitoring**: AWS Budgets with SNS notifications at 80%, 100%, 120% thresholds
- **Tag Compliance**: AWS Config rule checking for required tags (cost-center, owner)
- **Static Dashboard**: S3-hosted HTML dashboard for cost visualization

## Architecture

```
┌─────────────────┐
│  EventBridge    │──► Daily (9 AM UTC)
│  Scheduled Rules│──► Weekly (Mon 10 AM UTC)
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│           Lambda Functions                  │
│  ┌──────────────┐  ┌──────────────┐        │
│  │   Collector  │  │Weekly Report │        │
│  └──────┬───────┘  └──────┬───────┘        │
│         │                 │                 │
│         ▼                 ▼                 │
│  ┌─────────────────────────────┐           │
│  │      S3 Bucket              │           │
│  │  - Daily JSON reports       │           │
│  │  - Weekly CSV reports       │           │
│  │  - HTML dashboard           │           │
│  └─────────────────────────────┘           │
└─────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│   SNS Topic     │──► Email
│                 │──► Telegram (via Lambda)
│                 │──► Slack (via Chatbot)
└─────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Existing IAM Role** for Lambda execution (created manually via AWS Console)
3. **Terraform** >= 1.6.0
4. **Python** 3.11
5. **GitHub Repository** with OIDC configured for AWS deployments

## Quick Start

### 1. Configure Variables

Create a `terraform.tfvars` file in the `infra/` directory:

```hcl
# Required
lambda_role_name = "your-lambda-execution-role-name"

# Optional
notification_email = "your-email@example.com"
telegram_bot_token = "your-telegram-bot-token"
telegram_chat_id = "your-telegram-chat-id"
region = "us-west-2"
```

### 2. Build Lambda Packages

```bash
chmod +x scripts/build-lambdas.sh
./scripts/build-lambdas.sh
```

### 3. Deploy Infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply
```

## GitHub Actions CI/CD

The project includes a complete CI/CD pipeline that:

1. Builds Lambda deployment packages
2. Runs Terraform format, validate, and plan
3. Comments on PRs with plan output
4. Auto-deploys to AWS on merge to `main`

### Required GitHub Secrets

Configure these in your repository settings:

- `AWS_ROLE_ARN`: ARN of the OIDC role for GitHub Actions
- `LAMBDA_ROLE_NAME`: Name of your Lambda execution role
- `NOTIFICATION_EMAIL`: Email for SNS notifications (optional)
- `TELEGRAM_BOT_TOKEN`: Telegram bot token (optional)
- `TELEGRAM_CHAT_ID`: Telegram chat ID (optional)

## Telegram Bot Setup

1. Create a bot via [@BotFather](https://t.me/botfather)
2. Get your bot token
3. Get your chat ID by messaging [@userinfobot](https://t.me/userinfobot)
4. Add credentials to `terraform.tfvars` or GitHub Secrets

## Project Structure

```
cloud-cost-calculator/
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # CI/CD pipeline
├── infra/
│   ├── modules/
│   │   ├── iam/                    # IAM role data source
│   │   ├── sns/                    # SNS topic & subscriptions
│   │   ├── lambda/                 # Reusable Lambda module
│   │   ├── eventbridge/            # Scheduled rules
│   │   ├── budgets/                # AWS Budgets
│   │   ├── config_rule/            # Tag compliance
│   │   └── s3/                     # S3 bucket for reports
│   ├── main.tf                     # Root module
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   └── backend.tf                  # Terraform backend config
├── src/
│   ├── collector/                  # Daily cost collector
│   ├── weekly_report/              # Weekly report generator
│   └── telegram_notifier/          # Telegram notification handler
└── scripts/
    └── build-lambdas.sh            # Lambda build script
```

## Lambda Functions

### Cost Collector (`src/collector/app.py`)

- **Trigger**: Daily at 9 AM UTC (EventBridge)
- **Function**: Fetches daily cost data from Cost Explorer
- **Output**: JSON report to S3 (`reports/daily/YYYY-MM-DD.json`)
- **Alert**: SNS notification if cost exceeds threshold

### Weekly Report (`src/weekly_report/app.py`)

- **Trigger**: Weekly on Monday at 10 AM UTC (EventBridge)
- **Function**: Aggregates 30-day cost data
- **Output**: CSV report to S3 (`reports/weekly/YYYY-Www.csv`)
- **Optional**: HTML dashboard to S3 (`dashboard/index.html`)

### Telegram Notifier (`src/telegram_notifier/app.py`)

- **Trigger**: SNS topic subscription
- **Function**: Forwards SNS messages to Telegram
- **Format**: Markdown-formatted messages with subject and timestamp

## Outputs

After deployment, Terraform outputs:

- `s3_bucket`: S3 bucket name for reports
- `s3_website_endpoint`: Static website URL
- `sns_topic_arn`: SNS topic ARN
- `collector_lambda_arn`: Cost collector Lambda ARN
- `weekly_lambda_arn`: Weekly report Lambda ARN
- `telegram_lambda_arn`: Telegram notifier Lambda ARN
- `lambda_role_arn`: Lambda execution role ARN
- `budget_name`: AWS Budget name
- `config_rule_arn`: Config rule ARN

## Customization

### Adjust Schedules

Edit `infra/modules/eventbridge/variables.tf`:

```hcl
variable "collector_schedule" {
  default = "cron(0 9 * * ? *)"  # Daily at 9 AM UTC
}

variable "weekly_schedule" {
  default = "cron(0 10 ? * MON *)"  # Monday at 10 AM UTC
}
```

### Change Cost Threshold

Edit `infra/main.tf`:

```hcl
environment = {
  REPORT_BUCKET = module.s3.bucket
  SNS_TOPIC_ARN = module.sns.topic_arn
  DAILY_THRESHOLD = "100"  # Change threshold to $100
}
```

### Modify Budget Amount

Edit `infra/main.tf`:

```hcl
module "budgets" {
  source = "./modules/budgets"
  name = "${var.project}-${var.env}-budget"
  budget_amount = 100  # Change to $100
  sns_topic_arn = module.sns.topic_arn
}
```

## Monitoring

- **CloudWatch Logs**: `/aws/lambda/<function-name>`
- **EventBridge Rules**: Check execution history in AWS Console
- **SNS Topic**: Monitor message delivery in SNS console
- **S3 Bucket**: View reports in `reports/daily/` and `reports/weekly/`

## Troubleshooting

### Lambda Execution Errors

Check CloudWatch Logs:
```bash
aws logs tail /aws/lambda/cloud-cost-calculator-collector --follow
```

### Missing Cost Data

Ensure Cost Explorer is enabled in your AWS account:
```bash
aws ce get-cost-and-usage --time-period Start=2025-01-01,End=2025-01-02 --granularity DAILY --metrics UnblendedCost
```

### Telegram Not Working

Test the Lambda manually:
```bash
aws lambda invoke --function-name cloud-cost-calculator-telegram-notifier \
  --payload '{"message":"Test"}' response.json
```

## Security Best Practices

1. **IAM Roles**: Use least-privilege permissions
2. **Secrets**: Store sensitive data in GitHub Secrets or AWS Secrets Manager
3. **S3 Bucket**: Enable versioning and lifecycle policies
4. **Terraform State**: Use remote backend (S3 + DynamoDB)
5. **Cost Explorer**: Limit API calls to avoid charges

## Cost Considerations

- **Cost Explorer API**: ~$0.01 per request
- **Lambda**: Free tier covers most usage
- **S3**: Minimal storage costs
- **SNS**: First 1,000 email notifications free
- **EventBridge**: First 14 million events free

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues or questions, please open a GitHub issue.
