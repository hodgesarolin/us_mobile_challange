variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Cluster information from Phase 1
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# IRSA role ARNs from Phase 1
variable "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  type        = string
}

variable "external_dns_role_arn" {
  description = "ExternalDNS IAM role ARN"
  type        = string
}

# GitOps configuration
variable "gitops_repo_url" {
  description = "GitOps repository URL"
  type        = string
}

# ArgoCD configuration
variable "app_project_name" {
  description = "ArgoCD application project name"
  type        = string
  default     = "default"
}

variable "app_project_description" {
  description = "ArgoCD application project description"
  type        = string
  default     = "Default project"
}

variable "create_argocd_application_project" {
  description = "Create ArgoCD application project"
  type        = bool
  default     = true
}

variable "argocd_hostname" {
  description = "ArgoCD hostname"
  type        = string
  default     = "argo"
}

# Platform configuration
variable "domain_base" {
  description = "Base domain for ingress"
  type        = string
  default     = ""
}

variable "enable_external_dns" {
  description = "Enable ExternalDNS"
  type        = bool
  default     = false
}

variable "enable_rollouts_dashboard_ingress" {
  description = "Enable Argo Rollouts dashboard ingress"
  type        = bool
  default     = false
}

variable "rollouts_dashboard_hostname" {
  description = "Argo Rollouts dashboard hostname"
  type        = string
  default     = "rollouts"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}