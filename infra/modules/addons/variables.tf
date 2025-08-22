variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "domain_base" {
  description = "Base domain for Route 53 (optional)"
  type        = string
  default     = ""
}

variable "gitops_repo_url" {
  description = "GitOps repository URL"
  type        = string
}

variable "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  type        = string
}

variable "external_dns_role_arn" {
  description = "ExternalDNS IAM role ARN"
  type        = string
}

variable "app_project_name" {
  description = "Name of the ArgoCD application project"
  type        = string
  default     = "default-project"
}

variable "app_project_description" {
  description = "Description of the ArgoCD application project"
  type        = string
  default     = "Default Application Project"
}

variable "create_argocd_application_project" {
  description = "Whether to create ArgoCD application project and root app"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Whether to install ExternalDNS"
  type        = bool
  default     = true
}

variable "enable_rollouts_dashboard_ingress" {
  description = "Whether to create ingress for Rollouts Dashboard"
  type        = bool
  default     = true
}

variable "rollouts_dashboard_hostname" {
  description = "Hostname for Rollouts Dashboard (when using domain)"
  type        = string
  default     = "rollouts"
}

variable "argocd_hostname" {
  description = "Hostname for ArgoCD (when using domain)"
  type        = string
  default     = "argo"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}