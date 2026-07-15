#!/bin/bash

# ==============================================================================
# Day 5: Event-Driven Pipeline Testing Script
# Tests S3 → Lambda → SNS → Email pipeline
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
ACTION=${2:-test}
WORK_DIR="03-EventDriven/terraform/environments/$ENVIRONMENT"

log_info "🧪 Testing Event-Driven Pipeline for $ENVIRONMENT environment"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    log_info "Valid environments: dev, qa, prod"
    exit 1
fi

# Check if Terraform state exists
if [ ! -d "$WORK_DIR" ]; then
    log_error "Environment directory not found: $WORK_DIR"
    exit 1
fi

cd "$WORK_DIR"

# Check if infrastructure is deployed
if [ ! -f ".terraform/terraform.tfstate" ] && [ ! -f "terraform.tfstate" ]; then
    log_error "Terraform state not found. Please deploy the infrastructure first."
    log_info "Run: ./deploy-event-pipeline.sh $ENVIRONMENT"
    exit 1
fi

# Get infrastructure outputs
log_info "📋 Getting infrastructure information..."

S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name 2>/dev/null || echo "")
SNS_TOPIC=$(terraform output -raw sns_topic_arn 2>/dev/null || echo "")
LOG_GROUP=$(terraform output -raw lambda_log_group_name 2>/dev/null || echo "")

if [ -z "$S3_BUCKET" ] || [ -z "$LAMBDA_FUNCTION" ]; then
    log_error "Could not retrieve infrastructure information"
    log_info "Make sure the infrastructure is properly deployed"
    exit 1
fi

log_info "Infrastructure found:"
echo "• S3 Bucket: $S3_BUCKET"
echo "• Lambda Function: $LAMBDA_FUNCTION"
echo "• SNS Topic: ${SNS_TOPIC##*:}"
echo "• Log Group: $LOG_GROUP"

case "$ACTION" in
    "test")
        # Full end-to-end test
        log_info "🚀 Running end-to-end pipeline test..."
        
        # Create test files
        TEST_DIR="/tmp/s3-test-$$"
        mkdir -p "$TEST_DIR"
        
        # Create various test files
        log_info "📄 Creating test files..."
        
        echo "Hello from Day 5 Event-Driven Pipeline!" > "$TEST_DIR/hello.txt"
        echo '{"message": "JSON test file", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$TEST_DIR/data.json"
        
        # Create a small binary file
        dd if=/dev/zero of="$TEST_DIR/binary.dat" bs=1024 count=1 2>/dev/null
        
        # Upload files one by one with delays
        for file in "$TEST_DIR"/*; do
            filename=$(basename "$file")
            log_info "📤 Uploading $filename to S3..."
            
            aws s3 cp "$file" "s3://$S3_BUCKET/$filename"
            log_success "Uploaded: $filename"
            
            # Wait a moment for processing
            sleep 2
        done
        
        # Clean up test files
        rm -rf "$TEST_DIR"
        
        log_info "⏱️  Waiting for Lambda processing (30 seconds)..."
        sleep 30
        
        # Check Lambda logs
        log_info "📊 Checking Lambda execution logs..."
        aws logs tail "$LOG_GROUP" --since 5m --format short || true
        
        log_success "✅ Test completed!"
        log_info "📧 Check your email for notifications"
        ;;
        
    "status")
        # Check pipeline status
        log_info "📊 Checking pipeline status..."
        
        # Check S3 bucket
        log_info "🗄️  S3 Bucket status:"
        aws s3 ls "s3://$S3_BUCKET" --human-readable --summarize || log_warning "Bucket is empty"
        
        # Check Lambda function
        log_info "⚡ Lambda Function status:"
        aws lambda get-function --function-name "$LAMBDA_FUNCTION" --query 'Configuration.[State,LastUpdateStatus,Runtime,Timeout,MemorySize]' --output table
        
        # Check recent Lambda invocations
        log_info "📈 Recent Lambda invocations (last 1 hour):"
        aws logs filter-log-events --log-group-name "$LOG_GROUP" \
            --start-time $(($(date +%s) * 1000 - 3600000)) \
            --filter-pattern "START RequestId" \
            --query 'events[*].[eventId,message]' \
            --output table 2>/dev/null || log_info "No recent invocations found"
        
        # Check SNS subscriptions
        log_info "📧 SNS Subscription status:"
        aws sns list-subscriptions-by-topic --topic-arn "$SNS_TOPIC" \
            --query 'Subscriptions[*].[Protocol,Endpoint,ConfirmationWasAuthenticated]' \
            --output table
        ;;
        
    "logs")
        # Show recent logs
        log_info "📊 Showing recent Lambda logs..."
        aws logs tail "$LOG_GROUP" --follow --format short
        ;;
        
    "upload")
        # Interactive file upload
        if [ -z "$3" ]; then
            log_error "Please specify a file to upload"
            log_info "Usage: $0 $ENVIRONMENT upload <file-path>"
            exit 1
        fi
        
        FILE_PATH="$3"
        if [ ! -f "$FILE_PATH" ]; then
            log_error "File not found: $FILE_PATH"
            exit 1
        fi
        
        FILENAME=$(basename "$FILE_PATH")
        log_info "📤 Uploading $FILENAME to S3 bucket..."
        
        aws s3 cp "$FILE_PATH" "s3://$S3_BUCKET/$FILENAME"
        log_success "✅ File uploaded successfully!"
        
        log_info "⏱️  Waiting for processing (10 seconds)..."
        sleep 10
        
        log_info "📊 Recent logs:"
        aws logs tail "$LOG_GROUP" --since 1m --format short || true
        ;;
        
    "cleanup")
        # Clean up test files
        log_warning "🧹 Cleaning up S3 bucket contents..."
        read -p "This will delete all files in $S3_BUCKET. Continue? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            aws s3 rm "s3://$S3_BUCKET" --recursive
            log_success "✅ S3 bucket cleaned up"
        else
            log_info "Cleanup cancelled"
        fi
        ;;
        
    *)
        log_error "Invalid action: $ACTION"
        log_info "Valid actions: test, status, logs, upload, cleanup"
        log_info "Examples:"
        echo "  $0 dev test              # Run end-to-end test"
        echo "  $0 dev status            # Check pipeline status"
        echo "  $0 dev logs              # Show Lambda logs"
        echo "  $0 dev upload file.txt   # Upload specific file"
        echo "  $0 dev cleanup           # Clean up S3 bucket"
        exit 1
        ;;
esac

cd - > /dev/null