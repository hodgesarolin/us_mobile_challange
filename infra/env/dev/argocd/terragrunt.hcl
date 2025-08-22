# Load configurations
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.env"))
}

# Disable provider generation - argocd module handles its own providers
generate "provider" {
  path      = "providers_disabled.tf"
  if_exists = "skip"
  contents  = "# Providers managed by module"
}

# Only include backend configuration
remote_state {
  backend = "s3"
  config = {
    bucket         = "gitops-mvp-terraform-state-${local.env_vars.locals.aws_account_id}-${local.env_vars.locals.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.env_vars.locals.aws_region
    encrypt        = true
    dynamodb_table = "gitops-mvp-terraform-locks"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

terraform {
  source = "../../../modules//argocd"
}

# Get outputs from eks-setup
dependency "eks_setup" {
  config_path = "../eks-setup"
  
  mock_outputs = {
    cluster_name                              = "us-mobile-challenge-dev"
    cluster_endpoint                          = "https://mockendpoint.eks.amazonaws.com"
    cluster_certificate_authority_data       = "LS0tLS1CRUdJTi..."
    vpc_id                                   = "vpc-12345"
    aws_load_balancer_controller_role_arn    = "arn:aws:iam::123456789:role/mock"
    external_dns_role_arn                    = "arn:aws:iam::123456789:role/mock"
  }
}

inputs = {
  # From env.env file
  aws_account_id = local.env_vars.locals.aws_account_id
  aws_region     = local.env_vars.locals.aws_region
  environment    = local.env_vars.locals.environment
  
  # From EKS setup outputs
  cluster_name                              = dependency.eks_setup.outputs.cluster_name
  cluster_endpoint                          = dependency.eks_setup.outputs.cluster_endpoint
  cluster_certificate_authority_data       = dependency.eks_setup.outputs.cluster_certificate_authority_data
  vpc_id                                   = dependency.eks_setup.outputs.vpc_id
  aws_load_balancer_controller_role_arn    = dependency.eks_setup.outputs.aws_load_balancer_controller_role_arn
  external_dns_role_arn                    = dependency.eks_setup.outputs.external_dns_role_arn
  
  # GitOps repository
  gitops_repo_url = local.env_vars.locals.gitops_repo_url
  
  # ArgoCD Configuration
  app_project_name                     = "clippy-maze"
  app_project_description              = "Clippy Maze Game Project"
  create_argocd_application_project    = true
  argocd_hostname                      = "argo"
  
  # Platform Configuration (all disabled since no domain)
  domain_base                          = ""
  enable_external_dns                  = false
  enable_rollouts_dashboard_ingress    = false
  rollouts_dashboard_hostname          = "rollouts"
  
  # Tags
  tags = {
    Project     = "us_mobile_challange"
    Environment = local.env_vars.locals.environment
    ManagedBy   = "terragrunt"
    Component   = "argocd"
  }
}