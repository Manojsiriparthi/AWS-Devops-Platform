# ==============================================================================
# Dev Environment - EKS Variable Values
# ==============================================================================

# Cluster Configuration
cluster_version                      = "1.34"
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Dev: Open access
cluster_enabled_log_types           = ["api", "audit"]  # Reduced logging for cost

# Node Group Configuration (Cost-optimized for dev)
node_capacity_type     = "SPOT"                              # 60-70% cost savings
node_instance_types    = ["t3.medium", "t3a.medium"]         # Multiple types for spot availability
node_ami_type         = "AL2023_x86_64_STANDARD"
node_disk_size        = 20
node_desired_capacity = 2                                    # Start with 2 nodes
node_max_capacity     = 3                                    # Allow scaling up to 3
node_min_capacity     = 1                                    # Allow scaling down to 1
node_key_name         = null                                 # No SSH access needed