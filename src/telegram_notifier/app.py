import os
import json
import urllib.request
import urllib.parse
import traceback

telegram_bot_token = os.environ.get('telegram_bot_token')
telegram_chat_id = os.environ.get('telegram_chat_id')

def send_telegram_message(text, parse_mode='Markdown'):
    """Send message to Telegram bot"""
    if not telegram_bot_token or not telegram_chat_id:
        print("Warning: Telegram credentials not configured")
        return None
    
    url = f"https://api.telegram.org/bot{telegram_bot_token}/sendMessage"
    data = urllib.parse.urlencode({
        'chat_id': telegram_chat_id,
        'text': text,
        'parse_mode': parse_mode
    }).encode("utf-8")

    try:
        req = urllib.request.Request(url, data=data)
        with urllib.request.urlopen(req, timeout=10) as resp:
            result = resp.read().decode()
            print(f"Telegram API response: {result}")
            return result
    except Exception as e:
        print(f"Error sending Telegram message: {str(e)}")
        traceback.print_exc()
        raise

def format_sns_message(sns_record):
    """Format SNS message for Telegram"""
    subject = sns_record.get('Subject', 'AWS Notification')
    message = sns_record.get('Message', '')
    timestamp = sns_record.get('Timestamp', '')
    
    # Format with Markdown
    formatted = f"*{subject}*\n\n"
    formatted += f"{message}\n\n"
    if timestamp:
        formatted += f"_Time: {timestamp}_"
    
    return formatted

def lambda_handler(event, context):
    """
    Lambda handler for Telegram notifications
    Receives SNS events and forwards them to Telegram
    """
    try:
        print(f"Received event: {json.dumps(event)}")
        
        records = event.get('Records', [])

        if not records:
            # Manual invocation or test event
            message = "Test notification from AWS Cost Calculator"
            if 'message' in event:
                message = event['message']
            send_telegram_message(message)
            return {'statusCode': 200, 'body': 'Test message sent'}

        # Process SNS records
        for record in records:
            if 'Sns' in record:
                sns_data = record['Sns']
                formatted_message = format_sns_message(sns_data)
                send_telegram_message(formatted_message)
            else:
                # Unknown record type
                message = f"Unknown event:\n```\n{json.dumps(record, indent=2)}\n```"
                send_telegram_message(message)

        return {
            'statusCode': 200,
            'body': json.dumps({'status': 'ok', 'messages_sent': len(records)})
        }

    except Exception as e:
        error_msg = f"Error in Telegram notifier: {str(e)}"
        print(error_msg)
        traceback.print_exc()
        
        # Try to send error notification
        try:
            send_telegram_message(f"⚠️ Error: {str(e)}")
        except:
            pass
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
