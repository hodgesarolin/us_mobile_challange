output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform locks"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for Terraform locks"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "next_steps" {
  description = "Next steps to deploy the main infrastructure"
  value = <<-EOT
    
    State backend created successfully!
    
    Next steps:
    1. Deploy EKS cluster:
       cd ../infra/env/dev/eks-setup
       terragrunt init && terragrunt apply
    
    2. Update kubeconfig:
       aws eks update-kubeconfig --region ${var.aws_region} --name us-mobile-challenge-dev
    
    3. Deploy ArgoCD:
       cd ../argocd
       terragrunt init && terragrunt apply
    
    4. Get URLs:
       cd ../../../..
       ./get-urls.sh
    
    State backend details:
    - S3 Bucket: ${aws_s3_bucket.terraform_state.bucket}
    - DynamoDB Table: ${aws_dynamodb_table.terraform_locks.name}
    - Region: ${var.aws_region}
  EOT
}

output "terraform_commands" {
  description = "Commands to run after bootstrap"
  value = {
    step1 = "cd ../infra/env/dev/eks-setup && terragrunt init && terragrunt apply"
    step2 = "aws eks update-kubeconfig --region ${var.aws_region} --name us-mobile-challenge-dev"
    step3 = "cd ../argocd && terragrunt init && terragrunt apply"
    step4 = "cd ../../../.. && ./get-urls.sh"
  }
}