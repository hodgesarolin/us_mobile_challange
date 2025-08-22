# Load configurations
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.env"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//eks-setup"
}

inputs = {
  # From env.env file
  aws_account_id = local.env_vars.locals.aws_account_id
  aws_region     = local.env_vars.locals.aws_region
  environment    = local.env_vars.locals.environment
  
  # Cluster configuration
  cluster_name = local.env_vars.locals.cluster_name
  
  # Node group configuration (t3.small with 2 nodes for pod capacity)
  instance_type = "t3.small"
  min_size      = 1
  max_size      = 3
  desired_size  = 2
  capacity_type = "SPOT"
  
  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  availability_zones_count = 2
  
  # Kubernetes version
  kubernetes_version = "1.33"
  
  # Tags
  tags = {
    Project     = "us_mobile_challange"
    Environment = local.env_vars.locals.environment
    ManagedBy   = "terragrunt"
    Component   = "eks-setup"
  }
}