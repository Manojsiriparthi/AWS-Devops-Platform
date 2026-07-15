# ==============================================================================
# Dev Environment - EKS Configuration
# Calls the EKS module with dev-specific inputs
# ==============================================================================

# ------------------------------------------------------------------------------
# EKS Module
# ------------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  environment = "dev"
  
  # Cluster Configuration
  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types           = var.cluster_enabled_log_types
  
  # Node Group Configuration
  node_capacity_type     = var.node_capacity_type
  node_instance_types    = var.node_instance_types
  node_ami_type         = var.node_ami_type
  node_disk_size        = var.node_disk_size
  node_desired_capacity = var.node_desired_capacity
  node_max_capacity     = var.node_max_capacity
  node_min_capacity     = var.node_min_capacity
  node_key_name         = var.node_key_name

  common_tags = {
    Project     = "aws-devops-platform"
    Environment = "dev"
    ManagedBy   = "terraform"
    Component   = "kubernetes"
    Day         = "4"
  }
}

# ------------------------------------------------------------------------------
# Variables (passed via terraform.tfvars)
# ------------------------------------------------------------------------------
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit"]  # Reduced logging for dev to save costs
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  type        = string
  default     = "SPOT"  # Use spot instances for dev to save costs
}

variable "node_instance_types" {
  description = "List of instance types for the EKS Node Group"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]  # Multiple types for spot diversity
}

variable "node_ami_type" {
  description = "Type of Amazon Machine Image (AMI)"
  type        = string
  default     = "AL2_x86_64"
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_key_name" {
  description = "EC2 Key Pair name for SSH access to worker nodes"
  type        = string
  default     = null  # No SSH key needed for dev
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "node_group_status" {
  description = "EKS node group status"
  value       = module.eks.node_group_status
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${module.eks.region}"
}