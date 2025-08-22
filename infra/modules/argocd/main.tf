# ArgoCD: Platform Services
# AWS Load Balancer Controller, ArgoCD, Argo Rollouts
# Connects to existing EKS cluster from eks-setup

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Configure providers to connect to the existing EKS cluster
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", var.cluster_name,
        "--region", var.aws_region
      ]
    }
  }
}

provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  load_config_file       = false
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.aws_region
    ]
  }
}

# Use the existing addons module but with direct provider configuration
module "addons" {
  source = "../addons"
  
  cluster_name    = var.cluster_name
  aws_region      = var.aws_region
  vpc_id          = var.vpc_id
  domain_base     = var.domain_base
  gitops_repo_url = var.gitops_repo_url
  
  # IRSA role ARNs from Phase 1
  aws_load_balancer_controller_role_arn = var.aws_load_balancer_controller_role_arn
  external_dns_role_arn                = var.external_dns_role_arn
  
  # ArgoCD configuration
  app_project_name                     = var.app_project_name
  app_project_description              = var.app_project_description
  create_argocd_application_project    = var.create_argocd_application_project
  argocd_hostname                      = var.argocd_hostname
  
  # Platform configuration
  enable_external_dns                  = var.enable_external_dns
  enable_rollouts_dashboard_ingress    = var.enable_rollouts_dashboard_ingress
  rollouts_dashboard_hostname          = var.rollouts_dashboard_hostname
  
  tags = var.tags
}