# EKS Setup: Core Infrastructure
# VPC, EKS Cluster, IRSA Roles

module "vpc" {
  source = "../vpc"
  
  vpc_cidr                 = var.vpc_cidr
  availability_zones_count = var.availability_zones_count
  cluster_name            = var.cluster_name
  tags                    = var.tags
}

module "eks" {
  source = "../eks"
  
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  instance_type = var.instance_type
  capacity_type = var.capacity_type
  min_size      = var.min_size
  max_size      = var.max_size
  desired_size  = var.desired_size
  
  tags = var.tags
  
  depends_on = [module.vpc]
}

module "irsa" {
  source = "../irsa"
  
  cluster_name             = var.cluster_name
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_provider_url       = module.eks.oidc_provider_url
  aws_account_id          = var.aws_account_id
  aws_region              = var.aws_region
  
  tags = var.tags
  
  depends_on = [module.eks]
}