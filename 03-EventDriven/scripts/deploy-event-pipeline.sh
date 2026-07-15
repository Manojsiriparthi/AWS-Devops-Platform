#!/bin/bash

# ==============================================================================
# Day 5: Event-Driven Architecture Deployment Script
# Deploys S3 → Lambda → SNS → Email pipeline
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-east-1}
WORK_DIR="03-EventDriven/terraform/environments/$ENVIRONMENT"

log_info "🚀 Deploying Event-Driven Pipeline for $ENVIRONMENT environment"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    log_info "Valid environments: dev, qa, prod"
    exit 1
fi

# Check if directory exists
if [ ! -d "$WORK_DIR" ]; then
    log_error "Environment directory not found: $WORK_DIR"
    exit 1
fi

# Check prerequisites
log_info "📋 Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI not found. Please install AWS CLI."
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    log_error "Terraform not found. Please install Terraform."
    exit 1
fi

# Check Python (for Lambda function)
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 not found. Please install Python 3."
    exit 1
fi

# Verify AWS credentials
log_info "🔐 Verifying AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured or invalid"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
log_success "AWS credentials verified for account: $ACCOUNT_ID"

# Check email configuration
log_warning "📧 Email Configuration Check"
TFVARS_FILE="$WORK_DIR/terraform.tfvars"

if grep -q "your-email@example.com" "$TFVARS_FILE"; then
    log_error "Please update notification_emails in $TFVARS_FILE with your actual email address"
    log_info "Edit the file and replace 'your-email@example.com' with your real email"
    exit 1
fi

# Update backend configuration if needed
log_info "🔧 Checking backend configuration..."
BACKEND_FILE="$WORK_DIR/backend.tf"

if grep -q "terraform-state-bucket-your-account-id" "$BACKEND_FILE"; then
    log_warning "Backend configuration needs to be updated with your actual S3 bucket name"
    log_info "Attempting to auto-detect existing Terraform state bucket..."
    
    # Try to find existing terraform state bucket
    EXISTING_BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'terraform-state')].Name" --output text | head -1)
    
    if [ -n "$EXISTING_BUCKET" ]; then
        log_info "Found existing state bucket: $EXISTING_BUCKET"
        sed -i.bak "s/terraform-state-bucket-your-account-id/$EXISTING_BUCKET/g" "$BACKEND_FILE"
        log_success "Updated backend configuration with bucket: $EXISTING_BUCKET"
    else
        log_error "Could not find existing Terraform state bucket"
        log_info "Please manually update the bucket name in $BACKEND_FILE"
        exit 1
    fi
fi

# Validate Lambda source code
log_info "🐍 Validating Lambda source code..."
LAMBDA_SOURCE="../../../lambda-code/s3_notification_handler.py"

if [ ! -f "$WORK_DIR/$LAMBDA_SOURCE" ]; then
    log_error "Lambda source file not found: $WORK_DIR/$LAMBDA_SOURCE"
    exit 1
fi

# Test Python syntax
python3 -m py_compile "$WORK_DIR/$LAMBDA_SOURCE"
log_success "Lambda code syntax is valid"

# Deploy infrastructure
log_info "🏗️ Deploying Event-Driven infrastructure..."
cd "$WORK_DIR"

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init

# Validate configuration
log_info "Validating Terraform configuration..."
terraform validate

# Plan deployment
log_info "Planning Terraform deployment..."
terraform plan -out=tfplan

# Show what will be created
log_info "📊 Deployment Summary:"
echo "----------------------------------------"
terraform show -json tfplan | jq -r '
  .planned_values.root_module.child_modules[].resources[] | 
  select(.type != "random_id") | 
  "• " + .type + " : " + .name
' 2>/dev/null || terraform plan -out=tfplan
echo "----------------------------------------"

# Apply deployment
log_warning "⚠️  This will create AWS resources that may incur costs!"
read -p "Continue with deployment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Deployment cancelled"
    exit 0
fi

log_info "Applying Terraform deployment..."
terraform apply tfplan
rm -f tfplan

# Get deployment outputs
log_success "🎉 Event-Driven pipeline deployed successfully!"

log_info "📋 Deployment Information:"
echo "=========================================="
terraform output -json | jq -r '
  to_entries[] | 
  "• " + .key + ": " + (.value.value | tostring)
'
echo "=========================================="

# Display next steps
log_info "📧 Next Steps:"
echo "1. Check your email for SNS subscription confirmation"
echo "2. Click the confirmation link in the email"
echo "3. Test the pipeline by uploading a file to S3"
echo ""

log_info "🧪 Testing Commands:"
S3_BUCKET=$(terraform output -raw s3_bucket_name)
echo "# Test file upload:"
echo "echo 'Hello Day 5!' > test-file.txt"
echo "aws s3 cp test-file.txt s3://$S3_BUCKET/"
echo ""
echo "# Check Lambda logs:"
LAMBDA_LOG_GROUP=$(terraform output -raw lambda_log_group_name)
echo "aws logs tail $LAMBDA_LOG_GROUP --follow"
echo ""

log_success "✅ Day 5 Event-Driven Architecture deployment completed!"
log_info "Don't forget to confirm your email subscription before testing!"

cd - > /dev/null