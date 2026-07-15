# 🎬 Day 4 Enhanced: StreamFlix - Netflix-like React App on EKS

## 🎯 Enhanced Goals
Build a **production-ready Netflix-like React application**, containerize it with Docker, push to ECR, deploy to EKS private subnets, and expose it to the internet via **Application Load Balancer** on port 80.

## 🏗️ Complete Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Internet Users                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │ HTTP/HTTPS Traffic (Port 80/443)
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                 AWS Application Load Balancer                   │
│                    (Internet-facing)                           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EKS Cluster                                 │
│                 (Private Subnets)                              │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │ StreamFlix  │  │ StreamFlix  │  │ StreamFlix  │           │
│  │   Pod 1     │  │   Pod 2     │  │   Pod 3     │           │
│  │             │  │             │  │             │           │
│  │ React App   │  │ React App   │  │ React App   │           │
│  │ + Nginx     │  │ + Nginx     │  │ + Nginx     │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 What's New in Enhanced Day 4

### 🎬 **StreamFlix React Application**
- **Netflix-inspired UI** with modern design
- **Responsive design** for mobile, tablet, desktop
- **Movie catalogs** with hover effects and animations
- **Real-time system information** display
- **Kubernetes-aware** - shows pod details, node info, etc.

### 🐳 **Production Docker Setup**
- **Multi-stage build** for optimized image size
- **Security-hardened** with non-root user
- **Nginx optimization** with compression, caching
- **Health checks** and monitoring endpoints
- **ECR integration** for AWS-native container registry

### ☸️ **Advanced Kubernetes Deployment**
- **Application Load Balancer** for external access
- **Private subnet deployment** for security
- **Horizontal Pod Autoscaler** for dynamic scaling
- **Pod Disruption Budget** for high availability
- **Advanced health checks** and monitoring

### 🔒 **Production Security**
- **Private subnets** - no direct internet access to pods
- **ALB security groups** - controlled traffic flow
- **Container security** - non-root execution, capability dropping
- **Network policies** - pod-to-pod communication control

---

## 📂 Enhanced Project Structure

```
02-K8s/
├── frontend-app/                    # React Application
│   ├── src/                        # React source code
│   │   ├── components/             # Reusable components
│   │   │   ├── Header.js/css       # Navigation header
│   │   │   ├── Hero.js/css         # Hero section with slides
│   │   │   ├── MovieRow.js/css     # Movie catalog rows
│   │   │   └── Footer.js/css       # Infrastructure info footer
│   │   ├── App.js/css              # Main application
│   │   └── index.js/css            # Entry point
│   ├── public/                     # Static assets
│   ├── package.json                # Dependencies
│   ├── Dockerfile                  # Multi-stage Docker build
│   ├── nginx.conf                  # Production Nginx config
│   ├── default.conf                # Server configuration
│   └── .dockerignore              # Docker ignore rules
├── helm/nginx-app/                 # Enhanced Helm Chart
│   ├── templates/
│   │   ├── deployment.yaml         # Updated for React app
│   │   ├── service.yaml            # ClusterIP service
│   │   ├── ingress.yaml           # ALB configuration
│   │   └── configmap.yaml         # App configuration
│   ├── values.yaml                # Production values
│   └── values-dev.yaml            # Development overrides
├── scripts/
│   ├── build-and-push.sh          # Docker build & ECR push
│   ├── deploy-streamflix.sh       # Full deployment pipeline
│   └── deploy-app.sh              # Original deployment script
└── README-StreamFlix.md           # This enhanced guide
```

---

## 🚀 Quick Start: Deploy StreamFlix

### Prerequisites
- ✅ **EKS cluster** from Day 4 (running and accessible)
- ✅ **AWS CLI** configured with appropriate permissions
- ✅ **Docker** installed and running
- ✅ **kubectl** configured for your EKS cluster
- ✅ **Helm 3.x** installed

### Step 1: Update Your Email in ECR Repository Name (Optional)
If you want to customize the ECR repository name, edit the scripts:
```bash
# Edit these files and update ECR_REPO_NAME if desired
vim 02-K8s/scripts/build-and-push.sh
vim 02-K8s/scripts/deploy-streamflix.sh
```

### Step 2: One-Command Deployment 🚀
```bash
# Full deployment: Build + Push + Deploy
./02-K8s/scripts/deploy-streamflix.sh dev

# Or step by step:
# 1. Build and push Docker image
./02-K8s/scripts/build-and-push.sh dev

# 2. Deploy to Kubernetes with ALB
./02-K8s/scripts/deploy-streamflix.sh dev us-east-1 false
```

### Step 3: Access Your Application 🌐
After deployment completes (5-10 minutes), you'll get:
```bash
🌐 StreamFlix is available at:
   http://streamflix-dev-alb-1234567890.us-east-1.elb.amazonaws.com

🔗 Available Endpoints:
   • Main App: http://your-alb-url
   • Health Check: http://your-alb-url/health
   • Ready Check: http://your-alb-url/ready
   • API Info: http://your-alb-url/api/info
```

---

## 📱 StreamFlix Features

### 🎬 **Netflix-inspired Interface**
- **Header Navigation** - Logo, menu, user info, live system status
- **Hero Section** - Rotating featured content with autoplay
- **Movie Catalogs** - Multiple rows with smooth scrolling
- **Footer** - Detailed infrastructure information and links

### 📊 **Real-time System Information**
- **Pod Details** - Name, IP, node information
- **Environment Info** - Current environment, namespace
- **Infrastructure Flow** - Visual representation of ALB → EKS → Pods
- **Live Status** - Real-time connection status and timestamps

### 🎨 **Modern Design Elements**
- **Smooth Animations** - Fade-ins, hover effects, transitions
- **Responsive Layout** - Works on phone, tablet, desktop
- **Netflix Color Scheme** - Authentic red/black theme
- **Loading States** - Skeleton loaders and progress indicators

### 🔧 **Technical Features**
- **Health Endpoints** - `/health`, `/ready` for Kubernetes probes
- **System API** - `/api/info` for runtime information
- **Performance Optimized** - Gzip compression, caching, CDN-ready
- **Security Headers** - XSS protection, content security policy

---

## 🐳 Docker Implementation Details

### 🏗️ **Multi-stage Build Process**
```dockerfile
# Stage 1: Build React Application
FROM node:18-alpine AS builder
# Install dependencies, build React app
# Optimize for production

# Stage 2: Production Nginx Server  
FROM nginx:1.25-alpine AS production
# Copy built app, configure Nginx
# Security hardening, health checks
```

### 📊 **Image Optimization**
- **Small footprint** - Multi-stage build removes build dependencies
- **Alpine Linux** - Minimal base image for security
- **Layer caching** - Optimized for Docker layer reuse
- **Security scanning** - ECR automated vulnerability scanning

### 🔒 **Security Features**
```dockerfile
# Non-root execution
USER streamflix (1001:1001)

# Capability dropping
capabilities:
  drop: ["ALL"]

# Read-only root filesystem support
# Health check integration
# Security headers in Nginx
```

---

## ⚖️ Application Load Balancer Configuration

### 🌐 **Internet-facing ALB**
```yaml
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
  alb.ingress.kubernetes.io/healthcheck-path: /health
  alb.ingress.kubernetes.io/success-codes: "200"
```

### 🏥 **Advanced Health Checks**
- **Health Check Path**: `/health` - Application health status
- **Ready Check Path**: `/ready` - Kubernetes readiness
- **Success Codes**: `200` - Only healthy responses
- **Timeout**: 5 seconds with 3 retries

### 🏷️ **Resource Tagging**
```yaml
alb.ingress.kubernetes.io/tags: "Project=aws-devops-platform,Environment=dev,Component=frontend"
```

---

## 📊 Monitoring & Observability

### 📈 **Health Check Endpoints**
```bash
# Application health (returns JSON status)
curl http://your-alb-url/health

# Kubernetes readiness probe
curl http://your-alb-url/ready

# System information API
curl http://your-alb-url/api/info

# Nginx metrics (Prometheus compatible)
curl http://your-alb-url/metrics
```

### 📊 **Kubernetes Monitoring**
```bash
# Watch pod status
kubectl get pods -n dev -w

# View application logs
kubectl logs -f deployment/streamflix-app -n dev

# Check resource usage
kubectl top pods -n dev

# Monitor ALB status
kubectl describe ingress streamflix-app-ingress -n dev
```

### 📋 **AWS CloudWatch Integration**
- **ALB Metrics** - Request count, latency, error rates
- **EKS Logs** - Container logs forwarded to CloudWatch
- **Resource Metrics** - CPU, memory, network utilization

---

## 🔧 Customization & Configuration

### 🎨 **Customize the Application**
```bash
# Edit React components
vim 02-K8s/frontend-app/src/components/Header.js

# Update movie data
vim 02-K8s/frontend-app/src/App.js

# Modify styling
vim 02-K8s/frontend-app/src/components/Header.css

# Rebuild and deploy
./02-K8s/scripts/deploy-streamflix.sh dev
```

### ⚖️ **Configure Load Balancer**
```yaml
# Edit ALB settings in Helm values
vim 02-K8s/helm/nginx-app/values-dev.yaml

# Available annotations:
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:..."  # For HTTPS
alb.ingress.kubernetes.io/ssl-redirect: "443"
alb.ingress.kubernetes.io/backend-protocol: HTTP
```

### 📏 **Scaling Configuration**
```yaml
# Horizontal Pod Autoscaler
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# Resource limits
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi
```

---

## 🚨 Troubleshooting Guide

### 🔍 **Common Issues & Solutions**

#### 1. **ALB Not Accessible**
```bash
# Check ingress status
kubectl describe ingress streamflix-app-ingress -n dev

# Verify ALB security groups
aws elbv2 describe-load-balancers --names streamflix-dev-alb

# Check target group health
aws elbv2 describe-target-health --target-group-arn <arn>
```

#### 2. **Pods Not Starting**
```bash
# Check pod events
kubectl describe pod <pod-name> -n dev

# View logs
kubectl logs <pod-name> -n dev

# Check image pull status
kubectl get events -n dev --sort-by='.lastTimestamp'
```

#### 3. **ECR Authentication Issues**
```bash
# Re-authenticate to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Check ECR repository permissions
aws ecr describe-repositories --repository-names streamflix-app
```

#### 4. **Load Balancer Controller Issues**
```bash
# Check AWS Load Balancer Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify service account permissions
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
```

### 🔧 **Debug Commands**
```bash
# Get all resources in namespace
kubectl get all -n dev

# Check cluster info
kubectl cluster-info

# Verify node readiness
kubectl get nodes

# Test internal connectivity
kubectl run debug --image=busybox -it --rm -- sh
nslookup streamflix-app.dev.svc.cluster.local
```

---

## 💰 Cost Optimization

### 💵 **Estimated Costs (Development)**
| Component | Monthly Cost | Notes |
|-----------|--------------|--------|
| **ALB** | ~$16 | $0.0225/hour |
| **ECR Storage** | ~$1 | $0.10/GB per month |
| **EKS Control Plane** | ~$73 | $0.10/hour (existing) |
| **Worker Nodes** | ~$60 | 2x t3.medium (existing) |
| **Data Transfer** | ~$5 | Minimal for development |
| **Total** | **~$155/month** | Can be optimized |

### 💡 **Cost Optimization Tips**
```bash
# Use spot instances for worker nodes
# Scale down during off-hours
kubectl scale deployment streamflix-app --replicas=0 -n dev

# Delete ALB when not needed
helm uninstall streamflix-app -n dev

# Use smaller instance types
# Configure autoscaling policies

# Clean up unused ECR images
aws ecr list-images --repository-name streamflix-app --filter tagStatus=UNTAGGED
```

---

## 🔐 Security Best Practices

### 🛡️ **Network Security**
- ✅ **Private subnets** - Pods have no direct internet access
- ✅ **ALB security groups** - Only allow HTTP/HTTPS traffic
- ✅ **VPC endpoints** - Private communication with AWS services
- ✅ **Network policies** - Restrict pod-to-pod communication

### 🔒 **Container Security**
- ✅ **Non-root execution** - Containers run as user 1001
- ✅ **Capability dropping** - Remove unnecessary Linux capabilities
- ✅ **Image scanning** - ECR vulnerability scanning enabled
- ✅ **Distroless images** - Minimal attack surface

### 🔑 **Access Control**
- ✅ **IAM roles** - Service accounts with minimal permissions
- ✅ **RBAC** - Kubernetes role-based access control
- ✅ **Secrets management** - No hardcoded credentials
- ✅ **TLS encryption** - ALB supports SSL termination

---

## 🎯 Success Criteria Checklist

### ✅ **Application Deployment**
- [x] **React app** - Netflix-like interface running
- [x] **Docker image** - Built and pushed to ECR
- [x] **Kubernetes pods** - Running in private subnets
- [x] **Health checks** - All probes passing

### ✅ **Network Access**
- [x] **ALB deployed** - Internet-facing load balancer
- [x] **Port 80 access** - Public HTTP access working
- [x] **Private subnets** - Pods not directly accessible
- [x] **Security groups** - Proper traffic control

### ✅ **Production Readiness**
- [x] **Scaling** - HPA configured and working
- [x] **Monitoring** - Health endpoints responding
- [x] **Security** - Non-root execution, capabilities dropped
- [x] **Performance** - Resource limits and requests set

---

## 🚀 Next Steps

### 🔄 **CI/CD Integration**
- Integrate with **Jenkins/CodeBuild** from Day 1-3
- Automated **Docker builds** on code changes
- **Blue-green deployments** with Helm
- **Automated testing** pipeline integration

### 🔒 **Enhanced Security**
- **HTTPS/TLS** - SSL certificate integration
- **WAF** - Web Application Firewall
- **Network policies** - Pod communication restrictions
- **Secret management** - AWS Secrets Manager integration

### 📊 **Advanced Monitoring**
- **Prometheus/Grafana** - Custom metrics dashboards
- **Distributed tracing** - Request flow monitoring
- **Log aggregation** - Centralized logging
- **Alerting** - CloudWatch alarms and notifications

### 🌐 **Multi-Environment**
- **QA environment** - Separate EKS cluster
- **Production environment** - High availability setup
- **Environment promotion** - Automated deployment pipeline
- **Feature flags** - Dynamic feature management

---

## 🎉 Congratulations!

You've successfully built and deployed a **production-ready Netflix-like React application** on **AWS EKS** with:

- ✅ **Modern React frontend** with Netflix-inspired design
- ✅ **Production Docker setup** with multi-stage builds
- ✅ **Kubernetes deployment** in private subnets
- ✅ **Application Load Balancer** for internet access
- ✅ **Security best practices** and monitoring
- ✅ **Auto-scaling and high availability**

Your application is now:
- 🌐 **Accessible from the internet** via ALB on port 80
- 🔒 **Securely deployed** in private subnets  
- 📊 **Production-ready** with monitoring and scaling
- 🚀 **Ready for real users** with high availability

**StreamFlix is live!** 🎬🚀

---

*Built with ❤️ for the AWS DevOps Platform - Day 4 Enhanced*