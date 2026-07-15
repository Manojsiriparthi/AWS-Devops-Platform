#!/usr/bin/env python3
"""
S3 Event Handler Lambda Function
Triggers on S3 object creation events and sends email notifications via SNS
"""

import json
import boto3
import logging
from datetime import datetime
from urllib.parse import unquote_plus

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
sns = boto3.client('sns')

def lambda_handler(event, context):
    """
    Lambda function handler for S3 events
    
    Args:
        event: S3 event notification
        context: Lambda runtime context
        
    Returns:
        dict: Response with status and processed files
    """
    
    try:
        logger.info(f"Received event: {json.dumps(event, indent=2)}")
        
        processed_files = []
        
        # Process each record in the event
        for record in event.get('Records', []):
            if record.get('eventSource') == 'aws:s3':
                # Extract S3 event details
                bucket_name = record['s3']['bucket']['name']
                object_key = unquote_plus(record['s3']['object']['key'])
                event_name = record['eventName']
                event_time = record['eventTime']
                
                logger.info(f"Processing S3 event: {event_name} for {bucket_name}/{object_key}")
                
                # Get SNS topic ARN from environment variable
                import os
                sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
                
                if not sns_topic_arn:
                    logger.error("SNS_TOPIC_ARN environment variable not set")
                    continue
                
                # Create email notification
                success = send_notification(
                    sns_topic_arn=sns_topic_arn,
                    bucket_name=bucket_name,
                    object_key=object_key,
                    event_name=event_name,
                    event_time=event_time
                )
                
                if success:
                    processed_files.append({
                        'bucket': bucket_name,
                        'object_key': object_key,
                        'status': 'success'
                    })
                else:
                    processed_files.append({
                        'bucket': bucket_name,
                        'object_key': object_key,
                        'status': 'failed'
                    })
        
        logger.info(f"Successfully processed {len(processed_files)} files")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully processed {len(processed_files)} S3 events',
                'processed_files': processed_files
            }),
            'headers': {
                'Content-Type': 'application/json'
            }
        }
        
    except Exception as e:
        logger.error(f"Error processing S3 event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to process S3 event'
            }),
            'headers': {
                'Content-Type': 'application/json'
            }
        }

def send_notification(sns_topic_arn, bucket_name, object_key, event_name, event_time):
    """
    Send email notification via SNS
    
    Args:
        sns_topic_arn (str): SNS topic ARN
        bucket_name (str): S3 bucket name
        object_key (str): S3 object key
        event_name (str): S3 event type
        event_time (str): Event timestamp
        
    Returns:
        bool: True if successful, False otherwise
    """
    
    try:
        # Parse timestamp
        timestamp = datetime.fromisoformat(event_time.replace('Z', '+00:00'))
        formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S UTC')
        
        # Create subject and message
        subject = f"🚀 AWS S3 Notification: New file uploaded to {bucket_name}"
        
        message = f"""
🔔 S3 Event Notification - Day 5 AWS DevOps Platform

📁 BUCKET: {bucket_name}
📄 FILE: {object_key}
📅 EVENT: {event_name}
🕒 TIME: {formatted_time}

📋 Details:
• A new file has been uploaded to your S3 bucket
• This notification was triggered automatically by an S3 event
• The Lambda function processed the event and sent this SNS notification

🏗️ Infrastructure:
• Managed by: Terraform
• Environment: Event-Driven Architecture
• Pipeline: S3 → Lambda → SNS → Email

🔗 AWS Console Links:
• S3 Object: https://s3.console.aws.amazon.com/s3/object/{bucket_name}?prefix={object_key}
• S3 Bucket: https://s3.console.aws.amazon.com/s3/buckets/{bucket_name}

This is an automated notification from your AWS DevOps Platform (Day 5).
        """
        
        # Send SNS message
        response = sns.publish(
            TopicArn=sns_topic_arn,
            Message=message.strip(),
            Subject=subject
        )
        
        message_id = response.get('MessageId')
        logger.info(f"SNS message sent successfully. MessageId: {message_id}")
        
        return True
        
    except Exception as e:
        logger.error(f"Failed to send SNS notification: {str(e)}")
        return False

def get_file_info(bucket_name, object_key):
    """
    Get additional file information from S3 (optional enhancement)
    
    Args:
        bucket_name (str): S3 bucket name
        object_key (str): S3 object key
        
    Returns:
        dict: File metadata
    """
    
    try:
        s3 = boto3.client('s3')
        
        # Get object metadata
        response = s3.head_object(Bucket=bucket_name, Key=object_key)
        
        return {
            'size': response.get('ContentLength', 0),
            'last_modified': response.get('LastModified'),
            'content_type': response.get('ContentType', 'unknown'),
            'etag': response.get('ETag', '').strip('"')
        }
        
    except Exception as e:
        logger.warning(f"Could not retrieve file info for {bucket_name}/{object_key}: {str(e)}")
        return {}

# For local testing
if __name__ == "__main__":
    # Sample S3 event for testing
    sample_event = {
        "Records": [
            {
                "eventSource": "aws:s3",
                "eventName": "ObjectCreated:Put",
                "eventTime": "2026-07-15T10:00:00.000Z",
                "s3": {
                    "bucket": {"name": "my-test-bucket"},
                    "object": {"key": "uploads/test-file.txt"}
                }
            }
        ]
    }
    
    # Mock environment
    import os
    os.environ['SNS_TOPIC_ARN'] = 'arn:aws:sns:us-east-1:123456789012:test-topic'
    
    # Test the function
    result = lambda_handler(sample_event, None)
    print(json.dumps(result, indent=2))