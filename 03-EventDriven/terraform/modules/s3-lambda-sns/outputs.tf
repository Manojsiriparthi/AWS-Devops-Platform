# ==============================================================================
# S3-Lambda-SNS Module - Outputs
# ==============================================================================

# --- S3 Bucket Information ---
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.upload_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.upload_bucket.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.upload_bucket.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.upload_bucket.bucket_regional_domain_name
}

# --- Lambda Function Information ---
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.s3_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.s3_processor.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.s3_processor.invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

# --- SNS Topic Information ---
output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.file_notifications.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.file_notifications.name
}

# --- CloudWatch Log Group ---
output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "lambda_log_group_arn" {
  description = "ARN of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

# --- Useful Information for Testing ---
output "test_upload_command" {
  description = "AWS CLI command to test file upload"
  value       = "aws s3 cp <local-file> s3://${aws_s3_bucket.upload_bucket.id}/"
}

output "sns_subscription_status" {
  description = "Status information about SNS subscriptions"
  value = {
    for email, subscription in aws_sns_topic_subscription.email_notification : 
    email => {
      arn               = subscription.arn
      confirmation_pending = subscription.pending_confirmation
    }
  }
}