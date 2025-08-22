output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = module.irsa.aws_load_balancer_controller_role_arn
}

output "external_dns_role_arn" {
  description = "ExternalDNS IAM role ARN"
  value       = module.irsa.external_dns_role_arn
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}

output "eks_setup_completion_message" {
  description = "Message indicating EKS setup is complete"
  value = <<EOF
✅ EKS Setup (Core Infrastructure) Complete!

Next Steps:
1. Update your kubeconfig: ${module.eks.cluster_name}
   aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}

2. Verify cluster is ready:
   kubectl get nodes

3. Deploy ArgoCD and platform services:
   cd ../argocd
   terragrunt apply

The EKS cluster is ready for ArgoCD and AWS Load Balancer Controller deployment.
EOF
}