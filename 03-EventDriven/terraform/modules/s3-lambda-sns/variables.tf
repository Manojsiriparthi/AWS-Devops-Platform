# ==============================================================================
# S3-Lambda-SNS Module - Input Variables
# ==============================================================================

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Lambda Configuration
# ------------------------------------------------------------------------------
variable "lambda_source_dir" {
  description = "Directory containing the Lambda function source code"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

# ------------------------------------------------------------------------------
# SNS Configuration
# ------------------------------------------------------------------------------
variable "notification_emails" {
  description = "List of email addresses to receive notifications"
  type        = list(string)
  
  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "At least one notification email must be provided."
  }
}

# ------------------------------------------------------------------------------
# S3 Event Configuration
# ------------------------------------------------------------------------------
variable "s3_events" {
  description = "List of S3 events to trigger Lambda function"
  type        = list(string)
  default = [
    "s3:ObjectCreated:*"
  ]
}

variable "s3_filter_prefix" {
  description = "S3 object key prefix filter for events"
  type        = string
  default     = ""
}

variable "s3_filter_suffix" {
  description = "S3 object key suffix filter for events"
  type        = string
  default     = ""
}