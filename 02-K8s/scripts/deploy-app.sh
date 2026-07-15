#!/bin/bash

# ==============================================================================
# Day 4: Application Deployment Script
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
ACTION=${2:-install}
NAMESPACE=$ENVIRONMENT
HELM_RELEASE="nginx-app"
CHART_PATH="02-K8s/helm/nginx-app"
VALUES_FILE="02-K8s/helm/nginx-app/values-$ENVIRONMENT.yaml"

log_info "Deploying application to $ENVIRONMENT environment"

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    log_info "Valid environments: dev, qa, prod"
    exit 1
fi

if [[ ! "$ACTION" =~ ^(install|upgrade|uninstall|status)$ ]]; then
    log_error "Invalid action: $ACTION"
    log_info "Valid actions: install, upgrade, uninstall, status"
    exit 1
fi

# Check prerequisites
log_info "Checking prerequisites..."

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl."
    exit 1
fi

# Check Helm
if ! command -v helm &> /dev/null; then
    log_error "Helm not found. Please install Helm."
    exit 1
fi

# Verify cluster connection
log_info "Verifying cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster"
    log_info "Run: aws eks update-kubeconfig --name <cluster-name> --region us-east-1"
    exit 1
fi

# Check if chart exists
if [ ! -d "$CHART_PATH" ]; then
    log_error "Helm chart not found: $CHART_PATH"
    exit 1
fi

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    log_warning "Values file not found: $VALUES_FILE"
    log_info "Using default values.yaml"
    VALUES_FILE="$CHART_PATH/values.yaml"
fi

# Execute action
case "$ACTION" in
    "install"|"upgrade")
        log_info "Creating namespace if it doesn't exist..."
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
        
        # Lint the chart first
        log_info "Linting Helm chart..."
        helm lint "$CHART_PATH" -f "$VALUES_FILE"
        
        # Install or upgrade
        log_info "Running helm $ACTION..."
        helm upgrade --install "$HELM_RELEASE" "$CHART_PATH" \
            -f "$VALUES_FILE" \
            --namespace "$NAMESPACE" \
            --create-namespace \
            --wait \
            --timeout=300s
        
        log_success "Application deployed successfully!"
        ;;
    
    "uninstall")
        log_warning "This will remove the application from $ENVIRONMENT environment"
        read -p "Continue with uninstall? (yes/no): " confirm
        
        if [ "$confirm" != "yes" ]; then
            log_info "Uninstall cancelled"
            exit 0
        fi
        
        log_info "Uninstalling application..."
        helm uninstall "$HELM_RELEASE" --namespace "$NAMESPACE"
        log_success "Application uninstalled successfully!"
        ;;
    
    "status")
        log_info "Checking application status..."
        helm status "$HELM_RELEASE" --namespace "$NAMESPACE"
        ;;
esac

# Show deployment status (for install/upgrade)
if [[ "$ACTION" =~ ^(install|upgrade|status)$ ]]; then
    log_info "Deployment Status:"
    echo "----------------------------------------"
    
    # Helm status
    helm status "$HELM_RELEASE" --namespace "$NAMESPACE"
    echo "----------------------------------------"
    
    # Pod status
    log_info "Pod Status:"
    kubectl get pods -n "$NAMESPACE" -l app="$HELM_RELEASE"
    echo "----------------------------------------"
    
    # Service status
    log_info "Service Status:"
    kubectl get services -n "$NAMESPACE" -l app="$HELM_RELEASE"
    echo "----------------------------------------"
    
    # Wait for pods to be ready
    log_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=Ready pods -l app="$HELM_RELEASE" -n "$NAMESPACE" --timeout=300s
    
    # Get service information
    SERVICE_TYPE=$(kubectl get service "$HELM_RELEASE" -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    SERVICE_PORT=$(kubectl get service "$HELM_RELEASE" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
    
    log_success "Application is ready!"
    
    # Show access instructions
    log_info "Access Instructions:"
    if [ "$SERVICE_TYPE" == "ClusterIP" ]; then
        log_info "Service is ClusterIP type. Use port-forward to access:"
        log_info "kubectl port-forward service/$HELM_RELEASE $SERVICE_PORT:$SERVICE_PORT -n $NAMESPACE"
        log_info "Then access: http://localhost:$SERVICE_PORT"
        
        # Automatically start port-forward if requested
        read -p "Start port-forward now? (yes/no): " start_pf
        if [ "$start_pf" == "yes" ]; then
            log_info "Starting port-forward on port $SERVICE_PORT..."
            log_info "Press Ctrl+C to stop"
            kubectl port-forward service/"$HELM_RELEASE" "$SERVICE_PORT":"$SERVICE_PORT" -n "$NAMESPACE"
        fi
    else
        log_info "Service type: $SERVICE_TYPE"
        EXTERNAL_IP=$(kubectl get service "$HELM_RELEASE" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [ -n "$EXTERNAL_IP" ]; then
            log_info "External URL: http://$EXTERNAL_IP:$SERVICE_PORT"
        else
            log_info "External IP pending. Check with: kubectl get service $HELM_RELEASE -n $NAMESPACE"
        fi
    fi
    
    # Show logs
    log_info "Recent application logs:"
    kubectl logs -l app="$HELM_RELEASE" -n "$NAMESPACE" --tail=10
fi

log_success "Script completed successfully!"