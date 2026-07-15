#!/bin/bash

# ==============================================================================
# Day 4: EKS Cluster Setup Script
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
WORK_DIR="02-K8s/terraform/environments/$ENVIRONMENT"

log_info "Setting up EKS cluster for $ENVIRONMENT environment in $AWS_REGION"

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
log_info "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI not found. Please install AWS CLI."
    exit 1
fi

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    log_warning "kubectl not found. Installing kubectl..."
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    log_success "kubectl installed successfully"
fi

# Check Helm
if ! command -v helm &> /dev/null; then
    log_warning "Helm not found. Installing Helm..."
    # Install Helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
    log_success "Helm installed successfully"
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    log_error "Terraform not found. Please install Terraform."
    exit 1
fi

# Verify AWS credentials
log_info "Verifying AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured or invalid"
    exit 1
fi
log_success "AWS credentials verified"

# Deploy EKS infrastructure
log_info "Deploying EKS infrastructure..."
cd "$WORK_DIR"

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init

# Plan deployment
log_info "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply deployment
log_info "Applying Terraform deployment..."
log_warning "This will create AWS resources that incur costs!"
read -p "Continue with deployment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Deployment cancelled"
    exit 0
fi

terraform apply tfplan
rm -f tfplan

# Get cluster information
CLUSTER_NAME=$(terraform output -raw cluster_name)
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)

log_success "EKS cluster deployed successfully!"
log_info "Cluster Name: $CLUSTER_NAME"
log_info "Cluster Endpoint: $CLUSTER_ENDPOINT"

# Configure kubectl
log_info "Configuring kubectl..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"

# Verify cluster access
log_info "Verifying cluster access..."
kubectl get nodes

# Wait for nodes to be ready
log_info "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s

log_success "EKS cluster is ready!"

# Display cluster information
log_info "Cluster Information:"
echo "----------------------------------------"
kubectl get nodes -o wide
echo "----------------------------------------"
kubectl get namespaces
echo "----------------------------------------"

log_success "EKS setup completed successfully!"
log_info "Next step: Run ./deploy-app.sh $ENVIRONMENT to deploy the application"