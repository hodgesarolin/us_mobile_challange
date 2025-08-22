# Load project configuration  
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.env"))
}

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

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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
  
  default_tags {
    tags = var.tags
  }
}
EOF
}