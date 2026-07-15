# Day 5: Event-Driven Architecture - S3 → Lambda → SNS → Email

## 🎯 Goal
Create an event-driven pipeline where uploading a file to S3 automatically triggers a Lambda function that sends an email notification via SNS with the file details.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Event-Driven Pipeline                       │
│                                                                 │
│  📁 S3 Bucket        ⚡ Lambda          📧 SNS Topic           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │              │    │              │    │              │     │
│  │ File Upload  │───▶│ Event        │───▶│ Email        │     │
│  │              │    │ Handler      │    │ Notification │     │
│  │              │    │              │    │              │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                    │            │
│                                           ┌──────────────┐     │
│                                           │              │     │
│                                           │ Your Email   │     │
│                                           │ Inbox        │     │
│                                           │              │     │
│                                           └──────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

## 📂 Project Structure

```
03-EventDriven/
├── README.md                           # This file
├── lambda-code/                        # Lambda function source
│   ├── s3_notification_handler.py      # Main Lambda function
│   └── requirements.txt                # Python dependencies
├── scripts/                            # Deployment and testing scripts
│   ├── deploy-event-pipeline.sh        # Infrastructure deployment
│   └── test-pipeline.sh                # Testing and validation
└── terraform/                          # Infrastructure as Code
    ├── modules/
    │   └── s3-lambda-sns/              # Reusable module
    │       ├── main.tf                 # Main resources
    │       ├── variables.tf            # Input variables
    │       └── outputs.tf              # Output values
    └── environments/
        ├── dev/                        # Development environment
        │   ├── main.tf                 # Environment-specific config
        │   ├── backend.tf              # Terraform state backend
        │   └── terraform.tfvars        # Environment variables
        ├── qa/                         # QA environment (future)
        └── prod/                       # Production environment (future)
```

## 🚀 Quick Start Guide

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Python 3.x installed
- Valid email address for notifications

### Step 1: Update Configuration

1. **Update email address** in `terraform/environments/dev/terraform.tfvars`:
   ```hcl
   notification_emails = [
     "your-actual-email@example.com"  # Replace with your email
   ]
   ```

2. **Update backend configuration** in `terraform/environments/dev/backend.tf`:
   - Use the same S3 bucket from your Day 1-3 networking infrastructure
   - Update `bucket` and `dynamodb_table` names

### Step 2: Deploy Infrastructure

```bash
# Navigate to the project root
cd AWS-Devops-Platform

# Deploy the event-driven pipeline
./03-EventDriven/scripts/deploy-event-pipeline.sh dev
```

The script will:
- ✅ Validate prerequisites
- ✅ Check AWS credentials
- ✅ Deploy S3 bucket, Lambda function, and SNS topic
- ✅ Configure event triggers

### Step 3: Confirm Email Subscription

1. **Check your email** for an SNS subscription confirmation
2. **Click the confirmation link** in the email
3. You should see a confirmation page

### Step 4: Test the Pipeline

```bash
# Run end-to-end test
./03-EventDriven/scripts/test-pipeline.sh dev test

# Upload a specific file
./03-EventDriven/scripts/test-pipeline.sh dev upload myfile.txt

# Check pipeline status
./03-EventDriven/scripts/test-pipeline.sh dev status

# Watch Lambda logs in real-time
./03-EventDriven/scripts/test-pipeline.sh dev logs
```

## 🧪 Testing & Validation

### Manual Testing

1. **Upload a file via AWS CLI:**
   ```bash
   echo "Hello Day 5!" > test.txt
   aws s3 cp test.txt s3://YOUR_BUCKET_NAME/
   ```

2. **Upload via AWS Console:**
   - Navigate to the S3 bucket in AWS Console
   - Drag and drop a file
   - Check your email for notification

### Automated Testing

The test script creates multiple file types:
- **Text file** - Simple text content
- **JSON file** - Structured data with timestamp
- **Binary file** - Small binary data file

### Expected Results

✅ **S3 Upload**: File successfully uploaded to bucket  
✅ **Lambda Trigger**: Function invoked within seconds  
✅ **Email Notification**: Detailed email received with:
   - File name and bucket
   - Event type and timestamp  
   - Direct links to AWS Console
   - Infrastructure details

## 📊 Monitoring & Logs

### CloudWatch Logs
```bash
# View Lambda logs
aws logs tail /aws/lambda/dev-s3-events-processor --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/dev-s3-events-processor \
  --filter-pattern "ERROR"
```

### Metrics & Alarms
- **Lambda Invocations**: Monitor function execution count
- **Lambda Errors**: Track function failures
- **Lambda Duration**: Monitor execution time
- **SNS Delivery**: Track email delivery success

## 🔧 Configuration Options

### Environment Variables (Lambda)
- `SNS_TOPIC_ARN`: Target SNS topic for notifications
- `ENVIRONMENT`: Current environment (dev/qa/prod)

### Terraform Variables
- `notification_emails`: List of email recipients
- `s3_events`: S3 events to monitor (default: all ObjectCreated)
- `s3_filter_prefix`: Only files with this prefix
- `s3_filter_suffix`: Only files with this suffix
- `log_retention_days`: CloudWatch log retention period

### Example Filters
```hcl
# Only monitor uploads to 'important/' folder
s3_filter_prefix = "important/"

# Only monitor PDF files
s3_filter_suffix = ".pdf"

# Monitor both images and documents
s3_events = [
  "s3:ObjectCreated:Put",
  "s3:ObjectCreated:Post"
]
```

## 🔒 Security & Permissions

### IAM Roles Created
- **Lambda Execution Role**: Minimal permissions for S3 read and SNS publish
- **S3 Bucket Policy**: Restricts public access
- **SNS Topic Policy**: Allows Lambda to publish messages

### Security Features
- ✅ **Encryption**: S3 bucket uses AES-256 encryption
- ✅ **Versioning**: S3 versioning enabled for audit trail
- ✅ **Access Control**: Public access blocked on S3 bucket
- ✅ **Least Privilege**: IAM roles follow principle of least privilege

## 💰 Cost Optimization

### Development Environment
- **Lambda**: Pay per invocation (very low cost)
- **S3**: Standard storage pricing
- **SNS**: $0.50 per 1M requests
- **CloudWatch**: 7-day log retention to minimize storage

### Estimated Monthly Cost (Dev)
- **S3 Storage**: ~$0.02 per GB
- **Lambda Invocations**: ~$0.20 per 1M requests
- **SNS Messages**: ~$0.50 per 1M emails
- **CloudWatch Logs**: ~$0.50 per GB stored

**Total**: < $5/month for typical development usage

## 🚨 Troubleshooting

### Common Issues

1. **Email not received**
   - Check SNS subscription confirmation
   - Verify email address in terraform.tfvars
   - Check spam/junk folder

2. **Lambda not triggered**
   - Verify S3 event notification configuration
   - Check Lambda permissions for S3 bucket
   - Review CloudWatch logs for errors

3. **Permission errors**
   - Ensure AWS credentials have necessary permissions
   - Check IAM roles and policies
   - Verify S3 bucket policies

### Debug Commands
```bash
# Check S3 event configuration
aws s3api get-bucket-notification-configuration --bucket BUCKET_NAME

# Test Lambda function directly
aws lambda invoke --function-name FUNCTION_NAME response.json

# Check SNS subscriptions
aws sns list-subscriptions-by-topic --topic-arn TOPIC_ARN
```

## 🎉 Success Criteria

✅ **S3 Bucket**: Created and accessible  
✅ **Lambda Function**: Deployed and executable  
✅ **SNS Topic**: Created with email subscription  
✅ **Event Trigger**: S3 → Lambda connection working  
✅ **Email Notification**: Received with file details  
✅ **End-to-End Test**: Complete pipeline functional

## 🔄 Next Steps

After Day 5 completion:
- **Integration**: Connect with existing VPC infrastructure (Day 1-3)
- **CI/CD**: Add pipeline to Jenkins/CodeBuild (from Day 1-3)  
- **Monitoring**: Enhanced CloudWatch dashboards
- **Scaling**: Multi-environment deployment (QA, Prod)
- **Advanced Features**: File processing, content analysis

## 📚 Learning Outcomes

By completing Day 5, you will have:
- ✅ **Event-Driven Architecture**: Hands-on serverless experience
- ✅ **AWS Lambda**: Function deployment and configuration  
- ✅ **S3 Events**: Bucket notification setup
- ✅ **SNS Integration**: Email notification system
- ✅ **Terraform Modules**: Reusable infrastructure patterns
- ✅ **Testing Strategy**: Automated validation scripts
- ✅ **Monitoring**: CloudWatch logs and metrics

---

🎯 **Ready to build your event-driven pipeline? Start with the Quick Start Guide above!**