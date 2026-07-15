# ==============================================================================
# S3-Lambda-SNS Module - Main Configuration
# Creates S3 bucket, Lambda function, and SNS topic with email notifications
# ==============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name_prefix = "${var.environment}-s3-events"
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = "aws-devops-platform"
    Day         = "5"
    Component   = "event-driven"
    ManagedBy   = "terraform"
  })
}

# ------------------------------------------------------------------------------
# S3 Bucket for File Uploads
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "upload_bucket" {
  bucket = "${local.name_prefix}-bucket-${random_id.suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bucket"
    Type = "upload-bucket"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# SNS Topic for Email Notifications
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "file_notifications" {
  name = "${local.name_prefix}-notifications"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-notifications"
    Type = "notification-topic"
  })
}

# SNS Topic Policy
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    
    actions = [
      "SNS:Publish"
    ]
    
    resources = [aws_sns_topic.file_notifications.arn]
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "file_notifications" {
  arn    = aws_sns_topic.file_notifications.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email_notification" {
  for_each = toset(var.notification_emails)
  
  topic_arn = aws_sns_topic.file_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# ------------------------------------------------------------------------------
# Lambda Function ZIP Archive
# ------------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/lambda_function.zip"
  
  depends_on = [
    # Ensure lambda code exists
  ]
}

# ------------------------------------------------------------------------------
# Lambda IAM Role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-role"
    Type = "lambda-execution-role"
  })
}

# Lambda Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for SNS publishing
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.file_notifications.arn]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = ["${aws_s3_bucket.upload_bucket.arn}/*"]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# ------------------------------------------------------------------------------
# Lambda Function
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "s3_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.name_prefix}-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "s3_notification_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 60
  memory_size     = 256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.file_notifications.arn
      ENVIRONMENT   = var.environment
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-processor"
    Type = "s3-event-processor"
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs,
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.name_prefix}-processor"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-logs"
    Type = "lambda-log-group"
  })
}

# ------------------------------------------------------------------------------
# Lambda Permission for S3
# ------------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload_bucket.arn
}

# ------------------------------------------------------------------------------
# S3 Bucket Notification
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.upload_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = var.s3_events
    filter_prefix       = var.s3_filter_prefix
    filter_suffix       = var.s3_filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}