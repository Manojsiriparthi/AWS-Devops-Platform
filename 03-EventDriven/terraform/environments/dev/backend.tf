# ==============================================================================
# Dev Environment - Terraform Backend Configuration
# ==============================================================================

terraform {
  backend "s3" {
    # Note: Update these values to match your existing backend from Day 1-3
    # Use the same bucket and DynamoDB table created for the networking infrastructure
    
    bucket         = "terraform-state-bucket-your-account-id"  # Update with your bucket name
    key            = "envs/dev/event-driven/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"                   # Update with your table name
    encrypt        = true
    
    # Ensure state isolation from networking infrastructure
    # This creates a separate state file for the event-driven architecture
  }
}