# ==============================================================================
# Prod Environment - Main Configuration
# Calls the shared network module with prod-specific inputs
# ==============================================================================

variable "aws_region" {
  description = "AWS region for prod environment"
  type        = string
}

# ------------------------------------------------------------------------------
# Network Module
# ------------------------------------------------------------------------------
module "network" {
  source = "../../modules/network"

  environment          = "prod"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  common_tags = {
    Project     = "aws-devops-platform"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

# ------------------------------------------------------------------------------
# Variables (passed via terraform.tfvars)
# ------------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway"
  type        = bool
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "bastion_sg_id" {
  value = module.network.bastion_sg_id
}

output "web_sg_id" {
  value = module.network.web_sg_id
}

output "db_sg_id" {
  value = module.network.db_sg_id
}
