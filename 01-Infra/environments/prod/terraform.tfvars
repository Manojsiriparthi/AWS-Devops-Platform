# ==============================================================================
# Prod Environment - Variable Values
# ==============================================================================

aws_region = "us-east-1"

# VPC (different CIDR from dev/qa to avoid conflicts)
vpc_cidr = "10.2.0.0/16"

# Subnets (3 AZs for high availability in production)
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]

# NAT Gateway (one per AZ for high availability in production)
enable_nat_gateway = true
single_nat_gateway = false
