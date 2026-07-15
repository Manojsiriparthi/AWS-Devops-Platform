# Day 4: Kubernetes Application via Helm

## Goal
A basic Kubernetes cluster running a simple web application, deployed using a Helm chart.

## Architecture Overview
```
┌─────────────────────────────────────────────────────────┐
│                    EKS Cluster                          │
│  ┌───────────────┐    ┌───────────────┐               │
│  │  nginx-app    │    │  nginx-app    │               │
│  │   (Pod 1)     │    │   (Pod 2)     │               │
│  └───────────────┘    └───────────────┘               │
│            │                    │                      │
│            └────────┬───────────┘                      │
│                     │                                  │
│              ┌─────────────┐                           │
│              │   Service   │                           │
│              │ (ClusterIP) │                           │
│              └─────────────┘                           │
│                     │                                  │
│              ┌─────────────┐                           │
│              │   Ingress   │                           │
│              │  (ALB/NLB)  │                           │
│              └─────────────┘                           │
└─────────────────────────────────────────────────────────┘
                     │
               ┌─────────────┐
               │  Internet   │
               └─────────────┘
```

## Implementation Options

### Option A: EKS Cluster (Production-ready)
- **Pros**: Fully managed, integrates with existing VPC, production-ready
- **Cons**: Higher cost (~$0.10/hour for control plane + worker nodes)
- **Best for**: Production workloads, team environments

### Option B: Local Development (Cost-effective)
- **Kind**: Kubernetes in Docker
- **Minikube**: Local Kubernetes cluster
- **Pros**: Zero AWS costs, fast development
- **Cons**: Not accessible externally, local only

## Recommended Approach: EKS with Cost Optimization

### Phase 1: EKS Infrastructure (Terraform)
### Phase 2: Helm Chart Development
### Phase 3: Application Deployment
### Phase 4: Validation & Testing

---

## Phase 1: EKS Infrastructure

### 1.1 EKS Module Structure
```
02-K8s/
├── terraform/
│   ├── modules/
│   │   └── eks/
│   │       ├── main.tf           # EKS cluster + node group
│   │       ├── variables.tf      # Input parameters
│   │       ├── outputs.tf        # Cluster info
│   │       └── iam.tf            # EKS + Node IAM roles
│   └── environments/
│       ├── dev/
│       │   ├── main.tf           # Calls EKS module
│       │   ├── backend.tf        # State backend
│       │   └── terraform.tfvars  # Dev-specific values
│       └── qa/
│           ├── main.tf
│           ├── backend.tf
│           └── terraform.tfvars
├── helm/
│   └── nginx-app/               # Helm chart
└── scripts/
    ├── setup-cluster.sh        # Cluster setup script
    └── deploy-app.sh           # Application deployment
```

### 1.2 EKS Terraform Configuration

**Key Components:**
- EKS Cluster (1.29+)
- Managed Node Group (t3.medium, 2-4 nodes)
- VPC integration (use existing VPC from Day 1-3)
- IAM roles for cluster and nodes
- Security groups for EKS communication

**Cost Optimization:**
- Use existing VPC/subnets (no additional networking costs)
- t3.medium instances (cheaper than m5/c5)
- Spot instances for dev environment
- Auto-scaling (min: 1, max: 3 nodes)

---

## Phase 2: Helm Chart Development

### 2.1 Chart Structure
```
helm/nginx-app/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration
├── values-dev.yaml         # Dev overrides
├── values-qa.yaml          # QA overrides
├── templates/
│   ├── deployment.yaml     # Kubernetes Deployment
│   ├── service.yaml        # Kubernetes Service
│   ├── ingress.yaml        # AWS Load Balancer Controller
│   ├── configmap.yaml      # App configuration
│   └── _helpers.tpl        # Template helpers
└── README.md
```

### 2.2 Application Choice: Custom Nginx with Info Page

**Why Nginx:**
- Lightweight and fast
- Well-known and stable
- Easy to customize
- Good for demonstrating K8s concepts

**Custom Features:**
- Shows pod information (hostname, IP, environment)
- Health check endpoints
- Custom welcome page with infrastructure details
- Environment-specific branding

---

## Phase 3: Application Deployment

### 3.1 Deployment Strategy

**Dev Environment:**
- 2 replicas
- ClusterIP service
- Port-forward for testing
- No ingress (cost saving)

**QA Environment:**
- 3 replicas
- LoadBalancer service or Ingress
- External access for testing
- SSL termination (if using ALB)

### 3.2 Helm Commands
```bash
# Install/upgrade for dev
helm upgrade --install nginx-app ./helm/nginx-app \
  -f ./helm/nginx-app/values-dev.yaml \
  --namespace dev --create-namespace

# Install/upgrade for qa  
helm upgrade --install nginx-app ./helm/nginx-app \
  -f ./helm/nginx-app/values-qa.yaml \
  --namespace qa --create-namespace
```

---

## Phase 4: Validation & Testing

### 4.1 Health Checks
- Pod status and readiness
- Service endpoints
- Ingress/LoadBalancer connectivity
- Application functionality

### 4.2 Helm Validation
```bash
# Check deployment status
helm status nginx-app -n dev
kubectl get pods -n dev
kubectl get services -n dev

# Test application
kubectl port-forward service/nginx-app 8080:80 -n dev
# Access: http://localhost:8080

# Check logs
kubectl logs -l app=nginx-app -n dev --tail=50
```

---

## CI/CD Integration

### Option 1: Separate K8s Pipeline
- New CodeBuild project for K8s deployments
- Uses kubectl + helm commands
- Triggered after infrastructure deployment

### Option 2: Extended Infrastructure Pipeline
- Add K8s deployment phase to existing buildspec
- Single pipeline: Terraform → EKS → Helm → Validate

---

## Deliverables

### ✅ **Required Outputs:**
1. **Running EKS cluster** with 2+ worker nodes
2. **Deployed nginx application** via Helm chart
3. **Accessible web application** (via port-forward or LoadBalancer)
4. **Helm chart** that's configurable and reusable
5. **Validation scripts** proving app health

### ✅ **Success Criteria:**
- `kubectl get nodes` shows Ready nodes
- `helm status nginx-app` shows DEPLOYED
- Web app responds to HTTP requests
- Multiple replicas running and load-balanced
- Can upgrade app via `helm upgrade`

---

## Cost Estimation (Dev Environment)

| Component | Cost/Month | Notes |
|-----------|------------|--------|
| EKS Control Plane | ~$73 | $0.10/hour |
| 2x t3.medium nodes | ~$60 | $0.0416/hour each |
| EBS volumes | ~$10 | 20GB per node |
| **Total** | **~$143/month** | Can be reduced with Spot instances |

**Cost Optimization:**
- Use Spot instances (60-70% savings)
- Auto-scale to 0 nodes during off-hours
- Use existing VPC (no additional networking costs)
- Destroy dev cluster when not needed

---

## Quick Start Commands

```bash
# 1. Deploy EKS infrastructure
cd 02-K8s/terraform/environments/dev
terraform init && terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --name dev-eks-cluster --region us-east-1

# 3. Deploy application
cd ../../../../helm
helm upgrade --install nginx-app ./nginx-app -f ./nginx-app/values-dev.yaml --namespace dev --create-namespace

# 4. Test application
kubectl port-forward service/nginx-app 8080:80 -n dev
curl http://localhost:8080
```

---

## Next Steps (Day 5 Preview)

After Day 4 completion, we'll have:
- ✅ VPC networking (Days 1-3)
- ✅ Kubernetes application (Day 4)  
- 🔄 Ready for Day 5: S3 → Lambda → SNS event pipeline

The event-driven architecture will integrate with our existing infrastructure, possibly triggering deployments or notifications based on S3 events.