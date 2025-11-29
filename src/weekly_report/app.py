import os
import csv
import io
import json
import boto3
from datetime import datetime, timedelta, timezone, date

s3 = boto3.client('s3')
ce = boto3.client('ce')  # Cost Explorer
sns = boto3.client('sns')

BUCKET = os.environ.get('REPORT_BUCKET')
REPORT_PREFIX = os.environ.get('REPORT_PREFIX', 'reports/weekly/')
DAYS = int(os.environ.get('DAYS', '30'))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')  # optional
WRITE_HTML = os.environ.get('WRITE_HTML', 'false').lower() == 'true'


def iso_year_week(dt: date):
    y, w, _ = dt.isocalendar()
    return f"{y}-W{w:02d}"

def query_cost(start_date, end_date):
    # Groups: by DAY and by SERVICE
    resp = ce.get_cost_and_usage(
        TimePeriod={'Start': start_date, 'End': end_date},
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {'Type': 'DIMENSION', 'Key': 'SERVICE'}
        ],
    )
    return resp

def build_csv_from_response(resp):
    # Build rows: date, service, cost
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(['Date', 'Service', 'UnblendedCost'])
    # resp['ResultsByTime'] is list of days
    for day_obj in resp.get('ResultsByTime', []):
        day = day_obj['TimePeriod']['Start']
        for group in day_obj.get('Groups', []):
            service = group['Keys'][0]
            amount = group['Metrics']['UnblendedCost']['Amount']
            writer.writerow([day, service, amount])
    buf.seek(0)
    return buf.getvalue().encode('utf-8')  # bytes

def build_summary_text(resp):
    # Make a short summary (total per service over period)
    totals = {}
    for day_obj in resp.get('ResultsByTime', []):
        for group in day_obj.get('Groups', []):
            service = group['Keys'][0]
            amt = float(group['Metrics']['UnblendedCost']['Amount'])
            totals[service] = totals.get(service, 0.0) + amt
    # create short text
    top = sorted(totals.items(), key=lambda x: x[1], reverse=True)[:5]
    lines = ["Weekly cost summary (top services):"]
    for svc, amt in top:
        lines.append(f"{svc}: ${amt:,.2f}")
    return "\n".join(lines)

def lambda_handler(event, context):
    today = datetime.now(timezone.utc).date()
    start_date = (today - timedelta(days=DAYS)).isoformat()
    # Cost Explorer end date is exclusive, so pass tomorrow
    end_date = (today + timedelta(days=1)).isoformat()

    resp = query_cost(start_date, end_date)
    csv_bytes = build_csv_from_response(resp)

    # Compute filename as ISO year-week of 'today' (week containing today)
    filename = iso_year_week(today) + ".csv"
    key = f"{REPORT_PREFIX.rstrip('/')}/{filename}"

    # Upload CSV
    s3.put_object(Bucket=BUCKET, Key=key, Body=csv_bytes, ContentType='text/csv')
    print(f"Uploaded {key} to s3://{BUCKET}")

    # Optional HTML dashboard
    if WRITE_HTML:
        summary = build_summary_text(resp).replace("\n", "<br/>\n")
        html = f"<html><body><h2>Weekly cost summary</h2><p>{summary}</p></body></html>"
        s3.put_object(Bucket=BUCKET, Key="dashboard/index.html", Body=html.encode('utf-8'), ContentType='text/html')
        print("Wrote dashboard/index.html")

    # Optional SNS publish
    if SNS_TOPIC_ARN:
        short_text = build_summary_text(resp)
        sns.publish(TopicArn=SNS_TOPIC_ARN, Subject="Weekly Cost Summary", Message=short_text)
        print("Published SNS summary")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "report created", "s3_key": key})
    }


