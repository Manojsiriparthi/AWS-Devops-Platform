# ==============================================================================
# Dev Environment - Variable Values
# ==============================================================================

aws_region = "us-east-1"

# VPC
vpc_cidr = "10.0.0.0/16"

# Subnets (2 AZs)
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# NAT Gateway (single for cost saving in dev)
enable_nat_gateway = true
single_nat_gateway = true
