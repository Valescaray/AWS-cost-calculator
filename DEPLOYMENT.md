# Deployment Guide

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI configured
- [ ] Terraform >= 1.6.0 installed
- [ ] Python 3.11 installed
- [ ] Git repository created
- [ ] Lambda execution IAM role created manually in AWS Console

## Step 1: Create IAM Role for Lambda (Manual)

Since you've already created this role via AWS Console, ensure it has these policies:

1. **Trust Policy** (allows Lambda to assume the role):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

2. **Attached Policies**:
   - `AWSLambdaBasicExecutionRole` (for CloudWatch Logs)
   - Custom policy for Cost Explorer, S3, and SNS:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::*-reports/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "*"
    }
  ]
}
```

**Note the role name** - you'll need it for `lambda_role_name` variable.

## Step 2: Setup Terraform Backend (Optional but Recommended)

Create S3 bucket and DynamoDB table for Terraform state:

```bash
# Create S3 bucket for state
aws s3 mb s3://cloud-cost-calculator-tfstate-prod --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket cloud-cost-calculator-tfstate-prod \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name cloud-cost-calculator-tfstate-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2
```

Update `infra/backend.tf` with your bucket name if different.

## Step 3: Configure Variables

Create `infra/terraform.tfvars`:

```hcl
# Required
lambda_role_name = "your-lambda-execution-role-name"

# Optional
region = "us-west-2"
env = "production"
notification_email = "alerts@yourcompany.com"

# Telegram (optional)
telegram_bot_token = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
telegram_chat_id = "123456789"
```

**Security Note**: Never commit `terraform.tfvars` to Git. Add it to `.gitignore`.

## Step 4: Build Lambda Packages

```bash
# Make script executable
chmod +x scripts/build-lambdas.sh

# Build all Lambda packages
./scripts/build-lambdas.sh
```

Expected output:
```
Building Lambda deployment packages...

Building collector...
  Installing dependencies...
  Creating deployment package...
  ✓ Created infra/artifacts/collector.zip (2.1M)

Building weekly_report...
  Installing dependencies...
  Creating deployment package...
  ✓ Created infra/artifacts/weekly_report.zip (2.1M)

Building telegram_notifier...
  No dependencies to install
  Creating deployment package...
  ✓ Created infra/artifacts/telegram_notifier.zip (1.2K)

Build complete!
```

## Step 5: Deploy Infrastructure

```bash
cd infra

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply changes
terraform apply
```

Review the plan carefully. Type `yes` when prompted.

## Step 6: Verify Deployment

### Check Lambda Functions

```bash
# List Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cloud-cost-calculator`)].FunctionName'

# Test collector Lambda
aws lambda invoke \
  --function-name cloud-cost-calculator-collector \
  --log-type Tail \
  response.json

cat response.json
```

### Check S3 Bucket

```bash
# Get bucket name from Terraform output
BUCKET=$(terraform output -raw s3_bucket)

# List reports
aws s3 ls s3://$BUCKET/reports/ --recursive
```

### Check SNS Topic

```bash
# Get topic ARN
TOPIC_ARN=$(terraform output -raw sns_topic_arn)

# List subscriptions
aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN
```

### Confirm Email Subscription

If you configured `notification_email`, check your inbox for AWS SNS confirmation email and click the confirmation link.

## Step 7: Setup GitHub Actions (Optional)

### Create OIDC Provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create GitHub Actions IAM Role

Create a role with this trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/cloud-cost-calculator:*"
        }
      }
    }
  ]
}
```

Attach `AdministratorAccess` or a custom policy with Terraform permissions.

### Configure GitHub Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions:

- `AWS_ROLE_ARN`: ARN of the GitHub Actions role
- `LAMBDA_ROLE_NAME`: Name of Lambda execution role
- `NOTIFICATION_EMAIL`: (optional)
- `TELEGRAM_BOT_TOKEN`: (optional)
- `TELEGRAM_CHAT_ID`: (optional)

## Step 8: Test the System

### Trigger Cost Collector Manually

```bash
aws lambda invoke \
  --function-name cloud-cost-calculator-collector \
  response.json && cat response.json
```

### Trigger Weekly Report Manually

```bash
aws lambda invoke \
  --function-name cloud-cost-calculator-weekly \
  response.json && cat response.json
```

### Test Telegram Notifier

```bash
aws lambda invoke \
  --function-name cloud-cost-calculator-telegram-notifier \
  --payload '{"message":"Test notification"}' \
  response.json && cat response.json
```

### Check CloudWatch Logs

```bash
# Collector logs
aws logs tail /aws/lambda/cloud-cost-calculator-collector --follow

# Weekly report logs
aws logs tail /aws/lambda/cloud-cost-calculator-weekly --follow

# Telegram logs
aws logs tail /aws/lambda/cloud-cost-calculator-telegram-notifier --follow
```

## Troubleshooting

### Issue: "Access Denied" when calling Cost Explorer

**Solution**: Ensure Cost Explorer is enabled in your AWS account:
1. Go to AWS Console → Cost Management → Cost Explorer
2. Click "Enable Cost Explorer"
3. Wait 24 hours for data to populate

### Issue: Lambda timeout

**Solution**: Increase timeout in `infra/modules/lambda/variables.tf`:
```hcl
variable "timeout" {
  default = 120  # Increase to 120 seconds
}
```

### Issue: Terraform state locked

**Solution**: Unlock the state:
```bash
terraform force-unlock LOCK_ID
```

### Issue: No cost data in reports

**Solution**: Cost Explorer data has a 24-hour delay. Run the collector again tomorrow.

## Maintenance

### Update Lambda Code

1. Modify code in `src/`
2. Run `./scripts/build-lambdas.sh`
3. Run `terraform apply`

### Change Schedules

Edit `infra/modules/eventbridge/variables.tf` and run `terraform apply`.

### Update Budget Amount

Edit `infra/main.tf` budget_amount and run `terraform apply`.

## Cleanup

To destroy all resources:

```bash
cd infra
terraform destroy
```

**Warning**: This will delete all reports in S3. Backup important data first.

## Next Steps

1. Set up AWS Chatbot for Slack notifications
2. Create custom dashboards in CloudWatch
3. Add more Cost Explorer queries (by region, by account, etc.)
4. Implement cost anomaly detection
5. Add forecasting reports
