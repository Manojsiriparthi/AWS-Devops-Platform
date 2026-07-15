# ==============================================================================
# Dev Environment - Variable Values
# ==============================================================================

# AWS Configuration
aws_region = "us-east-1"

# Lambda Configuration  
lambda_source_dir = "../../../lambda-code"

# Email Notifications
# IMPORTANT: Update with your actual email address(es)
notification_emails = [
  "your-email@example.com"  # Replace with your actual email
]

# S3 Event Configuration
s3_events = [
  "s3:ObjectCreated:*"  # Trigger on any object creation
]

# Optional: Filter events by prefix/suffix
# s3_filter_prefix = "uploads/"     # Only files in uploads/ folder
# s3_filter_suffix = ".txt"        # Only .txt files

# Leave empty for all files
s3_filter_prefix = ""
s3_filter_suffix = ""