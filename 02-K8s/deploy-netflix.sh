#!/bin/bash

# ==============================================================================
# StreamFlix Netflix All-in-One Deployment Script
# Builds Docker → Pushes to ECR → Deploys to EKS with ALB → Validates
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
AWS_REGION="us-east-1"
ECR_REPO_NAME="streamflix-app"
HELM_RELEASE="streamflix-app"
NAMESPACE="netflix"
APP_DIR="02-K8s/frontend-app"
HELM_DIR="02-K8s/helm/streamflix-app"

echo "🎬 StreamFlix Netflix Deployment Pipeline"
echo "=========================================="
echo "🚀 Building React App → Docker → ECR → EKS → ALB"
echo "📦 Repository: $ECR_REPO_NAME"
echo "☸️  Namespace: $NAMESPACE"
echo "⚖️  Load Balancer: internet-facing ALB"
echo "=========================================="

# Step 1: Prerequisites Check
log_info "📋 Checking prerequisites..."

for tool in aws kubectl helm docker; do
    if ! command -v $tool &> /dev/null; then
        log_error "$tool not found. Please install $tool."
        exit 1
    fi
done

if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME"

log_success "Prerequisites verified ✅"

# Step 2: Create ECR Repository
log_info "📦 Setting up ECR repository..."

if ! aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
    log_info "Creating ECR repository: $ECR_REPO_NAME"
    aws ecr create-repository \
        --repository-name "$ECR_REPO_NAME" \
        --region "$AWS_REGION" \
        --image-tag-mutability MUTABLE \
        --image-scanning-configuration scanOnPush=true
fi

log_success "ECR repository ready: $ECR_URI"

# Step 3: Login to ECR
log_info "🔑 Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Step 4: Build Docker Image
log_info "🏗️ Building StreamFlix Docker image..."
cd "$APP_DIR"

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")

docker build \
    --build-arg REACT_APP_VERSION="1.0.0" \
    --build-arg REACT_APP_BUILD_DATE="$BUILD_DATE" \
    --build-arg REACT_APP_ENVIRONMENT="netflix" \
    -t "$ECR_REPO_NAME:latest" \
    -t "$ECR_REPO_NAME:$COMMIT_SHA" \
    .

cd - > /dev/null
log_success "Docker image built successfully 🐳"

# Step 5: Tag and Push to ECR
log_info "📤 Pushing to ECR..."
docker tag "$ECR_REPO_NAME:latest" "$ECR_URI:latest"
docker tag "$ECR_REPO_NAME:$COMMIT_SHA" "$ECR_URI:$COMMIT_SHA"

docker push "$ECR_URI:latest"
docker push "$ECR_URI:$COMMIT_SHA"

log_success "Images pushed to ECR ✅"

# Step 6: Install AWS Load Balancer Controller (if needed)
log_info "⚖️ Checking AWS Load Balancer Controller..."

CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)

if ! kubectl get deployment aws-load-balancer-controller -n kube-system &> /dev/null; then
    log_warning "Installing AWS Load Balancer Controller..."
    
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName="$CLUSTER_NAME" \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller \
        --wait
    
    log_success "AWS Load Balancer Controller installed"
else
    log_success "AWS Load Balancer Controller ready"
fi

# Step 7: Create Namespace
log_info "📁 Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Step 8: Update Helm values with ECR image
log_info "🔧 Updating Helm chart..."
TEMP_VALUES="/tmp/streamflix-values.yaml"
cp "$HELM_DIR/values.yaml" "$TEMP_VALUES"

# Update image repository
sed -i.bak "s|repository: .*|repository: \"$ECR_URI\"|g" "$TEMP_VALUES"
sed -i.bak "s|tag: .*|tag: \"latest\"|g" "$TEMP_VALUES"

log_success "Helm values updated with ECR image"

# Step 9: Deploy with Helm
log_info "🚀 Deploying StreamFlix to Kubernetes..."

helm upgrade --install "$HELM_RELEASE" "$HELM_DIR" \
    -f "$TEMP_VALUES" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    --timeout=600s

log_success "StreamFlix deployed to EKS! ☸️"

# Step 10: Wait for ALB and Get URL
log_info "⏳ Waiting for Application Load Balancer..."

for i in {1..20}; do
    ALB_URL=$(kubectl get ingress "$HELM_RELEASE-ingress" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -n "$ALB_URL" ]; then
        log_success "ALB is ready! 🌐"
        break
    fi
    
    log_info "Waiting for ALB... ($i/20)"
    sleep 15
done

# Step 11: Validate Deployment
log_info "🧪 Validating deployment..."

echo ""
log_success "📊 DEPLOYMENT STATUS:"
echo "=========================================="

kubectl get all -n "$NAMESPACE"

echo ""
echo "=========================================="

if [ -n "$ALB_URL" ]; then
    echo ""
    log_success "🎉 StreamFlix Netflix is LIVE!"
    echo ""
    echo "🌐 Access your Netflix app at:"
    echo "   👉 http://$ALB_URL"
    echo ""
    echo "🔗 Available endpoints:"
    echo "   • Main App: http://$ALB_URL"
    echo "   • Health: http://$ALB_URL/health"
    echo "   • Ready: http://$ALB_URL/ready"
    echo "   • API Info: http://$ALB_URL/api/info"
    
    echo ""
    log_info "🧪 Testing health endpoint..."
    sleep 30  # Wait for ALB to initialize
    
    if curl -s -o /dev/null -w "%{http_code}" "http://$ALB_URL/health" | grep -q "200"; then
        log_success "✅ Health check PASSED!"
    else
        log_warning "⏳ ALB still initializing... check manually"
    fi
    
else
    log_warning "ALB URL not yet available. Check with:"
    echo "kubectl get ingress -n $NAMESPACE"
fi

echo ""
echo "=========================================="
log_info "📈 Monitoring commands:"
echo ""
echo "# Watch all resources:"
echo "kubectl get all -n $NAMESPACE -w"
echo ""
echo "# View logs:"
echo "kubectl logs -f deployment/$HELM_RELEASE -n $NAMESPACE"
echo ""
echo "# Check ALB details:"
echo "kubectl describe ingress $HELM_RELEASE-ingress -n $NAMESPACE"
echo ""
echo "# Scale up/down:"
echo "kubectl scale deployment/$HELM_RELEASE --replicas=5 -n $NAMESPACE"

# Cleanup
rm -f "$TEMP_VALUES" "$TEMP_VALUES.bak"

echo ""
log_success "🎬 StreamFlix Netflix deployment completed!"
log_info "Your React app is running in EKS private subnets with ALB on port 80"
log_success "🍿 Enjoy your Netflix clone! 🎬"