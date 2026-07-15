#!/bin/bash

# ==============================================================================
# Terraform Deployment Script
# Usage: ./deploy.sh <environment> <action>
# Examples:
#   ./deploy.sh dev plan
#   ./deploy.sh qa apply
#   ./deploy.sh prod destroy
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

# Validate inputs
if [ $# -lt 2 ]; then
    log_error "Usage: $0 <environment> <action>"
    log_info "Environments: dev, qa, prod"
    log_info "Actions: plan, apply, destroy, validate"
    exit 1
fi

ENVIRONMENT=$1
ACTION=$2

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    log_info "Valid environments: dev, qa, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy|validate)$ ]]; then
    log_error "Invalid action: $ACTION"
    log_info "Valid actions: plan, apply, destroy, validate"
    exit 1
fi

# Set working directory
WORK_DIR="01-Infra/environments/$ENVIRONMENT"

if [ ! -d "$WORK_DIR" ]; then
    log_error "Environment directory not found: $WORK_DIR"
    exit 1
fi

log_info "Starting Terraform $ACTION for $ENVIRONMENT environment"
log_info "Working directory: $WORK_DIR"

cd "$WORK_DIR"

# Terraform operations
case "$ACTION" in
    validate)
        log_info "Validating Terraform configuration..."
        terraform init -backend=false
        terraform fmt -check -recursive ../../
        terraform validate
        log_success "Terraform validation completed successfully"
        ;;
    plan)
        log_info "Running Terraform plan..."
        terraform init -input=false
        terraform plan -input=false -out=tfplan
        log_success "Terraform plan completed successfully"
        log_warning "Review the plan above before running 'apply'"
        ;;
    apply)
        log_info "Running Terraform apply..."
        if [ ! -f "tfplan" ]; then
            log_warning "No plan file found. Generating plan first..."
            terraform init -input=false
            terraform plan -input=false -out=tfplan
        fi
        
        # Confirmation for prod
        if [ "$ENVIRONMENT" == "prod" ]; then
            log_warning "You are about to apply changes to PRODUCTION environment!"
            read -p "Are you sure you want to continue? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log_info "Operation cancelled"
                exit 0
            fi
        fi
        
        terraform apply -input=false -auto-approve tfplan
        rm -f tfplan
        log_success "Terraform apply completed successfully"
        ;;
    destroy)
        log_warning "You are about to DESTROY resources in $ENVIRONMENT environment!"
        read -p "Type '$ENVIRONMENT' to confirm destruction: " confirm
        if [ "$confirm" != "$ENVIRONMENT" ]; then
            log_info "Operation cancelled"
            exit 0
        fi
        
        terraform init -input=false
        terraform destroy -input=false -auto-approve
        log_success "Terraform destroy completed successfully"
        ;;
esac

log_success "Operation completed for $ENVIRONMENT environment"