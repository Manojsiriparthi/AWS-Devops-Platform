# ==============================================================================
# Dev Environment - Remote State Backend for EKS
# ==============================================================================

terraform {
  backend "s3" {
    bucket  = "demo-eks-manoj-shopcase"
    key     = "envs/dev/eks/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}