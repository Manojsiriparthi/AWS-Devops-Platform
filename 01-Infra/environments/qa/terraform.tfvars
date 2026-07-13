# ==============================================================================
# QA Environment - Variable Values
# ==============================================================================

aws_region = "us-east-1"

# VPC (different CIDR from dev to avoid conflicts)
vpc_cidr = "10.1.0.0/16"

# Subnets (2 AZs)
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# NAT Gateway (single for cost saving in qa)
enable_nat_gateway = true
single_nat_gateway = true
