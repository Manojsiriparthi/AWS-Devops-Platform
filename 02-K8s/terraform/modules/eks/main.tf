# ==============================================================================
# EKS Module - Main Configuration
# Creates EKS cluster with managed node group using existing VPC
# ==============================================================================

# Data source to get existing VPC (created in Day 1-3)
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  
  filter {
    name   = "tag:Tier"
    values = ["public"]
  }
}

# ------------------------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-eks-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(data.aws_subnets.private.ids, data.aws_subnets.public.ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_service_policy,
  ]

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-eks-cluster"
    Environment = var.environment
  })
}

# ------------------------------------------------------------------------------
# EKS Node Group
# ------------------------------------------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-eks-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = data.aws_subnets.private.ids
  
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types
  ami_type       = var.node_ami_type
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  remote_access {
    ec2_ssh_key = var.node_key_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_registry_policy,
  ]

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-eks-nodes"
    Environment = var.environment
  })
}

# ------------------------------------------------------------------------------
# EKS Add-ons
# ------------------------------------------------------------------------------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  
  tags = merge(var.common_tags, {
    Name        = "${var.environment}-vpc-cni"
    Environment = var.environment
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  
  depends_on = [aws_eks_node_group.main]
  
  tags = merge(var.common_tags, {
    Name        = "${var.environment}-coredns"
    Environment = var.environment
  })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  
  tags = merge(var.common_tags, {
    Name        = "${var.environment}-kube-proxy"
    Environment = var.environment
  })
}