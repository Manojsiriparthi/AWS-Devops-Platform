# ==============================================================================
# Dev Environment - Remote State Backend
# ==============================================================================
# NOTE: Update the bucket name and region to match your actual S3 state bucket.
# The S3 bucket and DynamoDB table must be created BEFORE running terraform init.
# ==============================================================================

terraform {
  backend "s3" {
    bucket       = "demo-eks-manoj-shopcase" # <-- CHANGE to your bucket name
    key          = "envs/dev/network/terraform.tfstate"
    region       = "us-east-1" # <-- CHANGE to your region
    use_lockfile = "true"
    encrypt      = true
  }
}
