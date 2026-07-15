# ==============================================================================
# Dev Environment - Event-Driven S3-Lambda-SNS Configuration
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "aws-devops-platform"
      Environment = "dev"
      ManagedBy   = "terraform"
      Day         = "5"
      Owner       = "devops-team"
    }
  }
}

# ------------------------------------------------------------------------------
# S3-Lambda-SNS Module
# ------------------------------------------------------------------------------
module "s3_lambda_sns" {
  source = "../../modules/s3-lambda-sns"
  
  environment        = "dev"
  lambda_source_dir  = var.lambda_source_dir
  notification_emails = var.notification_emails
  
  # Development-specific configuration
  log_retention_days = 7  # Shorter retention for dev to save costs
  
  # S3 event configuration
  s3_events        = var.s3_events
  s3_filter_prefix = var.s3_filter_prefix
  s3_filter_suffix = var.s3_filter_suffix
  
  common_tags = {
    CostCenter    = "development"
    Team          = "devops"
    Backup        = "false"  # No backup needed for dev
    Monitoring    = "basic"
  }
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_source_dir" {
  description = "Directory containing Lambda source code"
  type        = string
  default     = "../../../lambda-code"
}

variable "notification_emails" {
  description = "List of email addresses for notifications"
  type        = list(string)
}

variable "s3_events" {
  description = "List of S3 events to monitor"
  type        = list(string)
  default = [
    "s3:ObjectCreated:*"
  ]
}

variable "s3_filter_prefix" {
  description = "S3 object key prefix filter"
  type        = string
  default     = ""
}

variable "s3_filter_suffix" {
  description = "S3 object key suffix filter"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "s3_bucket_name" {
  description = "Name of the S3 bucket for file uploads"
  value       = module.s3_lambda_sns.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_lambda_sns.s3_bucket_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.s3_lambda_sns.lambda_function_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.s3_lambda_sns.sns_topic_arn
}

output "test_upload_command" {
  description = "Command to test file upload"
  value       = module.s3_lambda_sns.test_upload_command
}

output "lambda_log_group_name" {
  description = "CloudWatch log group for Lambda function"
  value       = module.s3_lambda_sns.lambda_log_group_name
}

output "sns_subscription_status" {
  description = "SNS subscription confirmation status"
  value       = module.s3_lambda_sns.sns_subscription_status
}