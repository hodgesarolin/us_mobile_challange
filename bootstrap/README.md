# Bootstrap Terraform State Backend

This directory contains Terraform configuration to bootstrap the remote state backend (S3 + DynamoDB) for the main GitOps infrastructure.

## Why Bootstrap?

The main infrastructure uses Terragrunt with remote state, but we need somewhere to store that state. This bootstrap creates:

1. **S3 Bucket** - Stores Terraform state files
2. **DynamoDB Table** - Provides state locking
3. **Configuration Files** - Auto-generates Terragrunt configs for main infrastructure

## Quick Start

1. **Edit the centralized configuration** (ONLY FILE TO EDIT):
   ```bash
   # Edit infra/env/dev/env.env and update these 3 values:
   #   - aws_account_id = "YOUR_AWS_ACCOUNT_ID" 
   #   - aws_region = "YOUR_REGION"
   #   - gitops_repo_url = "https://github.com/YOUR_USERNAME/YOUR_REPO.git"
   ```

2. **Generate terraform.tfvars and deploy**:
   ```bash
   cd bootstrap/
   ./generate-tfvars.sh  # Auto-generates terraform.tfvars from env.env
   terraform init && terraform apply
   ```

3. **Deploy main infrastructure**:
   ```bash
   cd ../infra/env/dev/eks-setup
   terragrunt init && terragrunt apply
   aws eks update-kubeconfig --region us-east-1 --name us-mobile-challenge-dev
   
   cd ../argocd
   terragrunt init && terragrunt apply
   ```

## What Gets Created

### S3 Bucket
- **Name**: `gitops-mvp-terraform-state-{account-id}-{region}`
- **Versioning**: Enabled
- **Encryption**: AES256
- **Public Access**: Blocked
- **Lifecycle**: Transitions old versions to cheaper storage

### DynamoDB Table
- **Name**: `gitops-mvp-terraform-locks`
- **Purpose**: State locking to prevent concurrent modifications
- **Billing**: Provisioned (5 RCU/WCU)
- **Key**: `LockID` (String)

### Configuration
The S3 bucket and DynamoDB table created here are referenced in:
- `infra/env/dev/eks-setup/terragrunt.hcl` - EKS infrastructure state
- `infra/env/dev/argocd/terragrunt.hcl` - ArgoCD infrastructure state

## Cost

Estimated monthly cost for state backend:
- **S3 bucket**: ~$0.50/month (for small state files)
- **DynamoDB**: ~$1.25/month (5 RCU/WCU)
- **Total**: ~$1.75/month

## Security Features

- S3 bucket encryption at rest
- Public access blocked
- DynamoDB encryption at rest (default)
- IAM permissions follow least privilege

## Cleanup

To destroy the bootstrap (⚠️ **WARNING**: This will destroy state storage):

```bash
terraform destroy
```

**Note**: Only do this after destroying all infrastructure that uses this state backend!

## Troubleshooting

### Error: Bucket already exists
If the S3 bucket name conflicts, it means someone else is using that name. The bucket names are globally unique across all AWS accounts. Change the `project_name` in `terraform.tfvars`.

### Error: Cannot assume role
Ensure your AWS credentials have permissions to:
- Create S3 buckets
- Create DynamoDB tables
- Create/read local files

### Error: Access denied
Make sure your AWS credentials are configured:
```bash
aws configure
# or
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

## Integration with Main Infrastructure

After bootstrap:
1. Main infrastructure will store state in the created S3 bucket
2. State locking prevents conflicts during concurrent operations
3. All Terraform operations are tracked and versioned
4. State is encrypted and secure

This gives you:
- ✅ **Persistent state** across team members
- ✅ **State locking** prevents corruption
- ✅ **Version history** for rollbacks
- ✅ **Encryption** for security
- ✅ **Automated lifecycle** for cost optimization