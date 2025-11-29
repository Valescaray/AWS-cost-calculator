import json
import boto3
import os
import datetime
from decimal import Decimal

s3 = boto3.client('s3')
ce = boto3.client('ce')
sns = boto3.client('sns')

BUCKET = os.environ['REPORT_BUCKET']
SNS_ARN = os.environ.get('SNS_TOPIC_ARN')
DAILY_THRESHOLD = float(os.environ.get('DAILY_THRESHOLD', '10'))

def decimal_default(obj):
    """JSON serializer for Decimal objects"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")

def lambda_handler(event, context):
    try:
        # Last 24 hours: start = yesterday, end = today (Cost Explorer End is exclusive)
        end = datetime.date.today()
        start = end - datetime.timedelta(days=1)
        
        print(f"Fetching cost data from {start} to {end}")

        resp = ce.get_cost_and_usage(
            TimePeriod={'Start': start.isoformat(), 'End': end.isoformat()},
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type':'DIMENSION','Key':'SERVICE'}]
        )

        # Store raw report
        report_key = f"reports/daily/daily.json"
        s3.put_object(
            Bucket=BUCKET, 
            Key=report_key, 
            Body=json.dumps(resp, default=decimal_default, indent=2), 
            ContentType='application/json'
        )
        print(f"Uploaded report to s3://{BUCKET}/{report_key}")

        # Spike detection
        total_cost = 0.0
        service_costs = {}
        
        if resp.get('ResultsByTime'):
            for day_obj in resp['ResultsByTime']:
                # Get total cost for the day
                if 'Total' in day_obj and 'UnblendedCost' in day_obj['Total']:
                    amount_str = day_obj['Total']['UnblendedCost'].get('Amount', '0')
                    total_cost += float(amount_str)
                
                # Get per-service costs
                for group in day_obj.get('Groups', []):
                    service = group['Keys'][0]
                    amount = float(group['Metrics']['UnblendedCost']['Amount'])
                    service_costs[service] = service_costs.get(service, 0.0) + amount

        print(f"Total cost: ${total_cost:.2f}, Threshold: ${DAILY_THRESHOLD:.2f}")

        # Alert if threshold exceeded
        if total_cost > DAILY_THRESHOLD and SNS_ARN:
            # Sort services by cost
            top_services = sorted(service_costs.items(), key=lambda x: x[1], reverse=True)[:5]
            
            message = f"⚠️ Daily Cost Alert\n\n"
            message += f"Total Cost: ${total_cost:.2f}\n"
            message += f"Threshold: ${DAILY_THRESHOLD:.2f}\n"
            message += f"Date: {start.isoformat()}\n\n"
            message += "Top Services:\n"
            for service, cost in top_services:
                message += f"  • {service}: ${cost:.2f}\n"
            
            sns.publish(
                TopicArn=SNS_ARN, 
                Subject=f"AWS Cost Alert: ${total_cost:.2f}",
                Message=message
            )
            print(f"Published alert to SNS: cost ${total_cost:.2f} exceeded threshold ${DAILY_THRESHOLD:.2f}")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "ok",
                "total_cost": total_cost,
                "report_key": report_key,
                "alert_sent": total_cost > DAILY_THRESHOLD
            })
        }
        
    except Exception as e:
        print(f"Error in cost collector: {str(e)}")
        import traceback
        traceback.print_exc()
        
        # Send error notification
        if SNS_ARN:
            sns.publish(
                TopicArn=SNS_ARN,
                Subject="Cost Collector Error",
                Message=f"Error collecting cost data: {str(e)}"
            )
        
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
