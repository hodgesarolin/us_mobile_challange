# GitOps-Based Deployment Pipeline on AWS EKS

A fully automated, production-ready GitOps CI/CD pipeline featuring **blue/green deployments**, **automated rollbacks**, and a playable **Clippy Maze game** as a demonstration application.

[![Architecture](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-blue)](https://argoproj.github.io/cd/)
[![Deployments](https://img.shields.io/badge/Deployments-Blue%2FGreen-green)](https://argoproj.github.io/rollouts/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What This Demonstrates

- **GitOps CI/CD Pipeline** - Git commits → ArgoCD → automated deployments
- **Blue/Green Deployments** with automatic rollback on failure  
- **GitOps Automation** - commit to deploy via ArgoCD + Helm
- **Interactive Demo App** - Clippy Maze game with v1→v2 improvements  
- **Production Infrastructure** - EKS, ALB, IRSA, Network Policies
- **Observability** - ArgoCD + Rollouts dashboards
- **Cost Optimized** - Spot instances, auto-scaling, easy teardown

## Quick Start

### Manual Deployment

```bash
# Clone and fork the repository
git clone <your-fork>
cd us_mobile_challange

# 1. Configure your deployment (edit 2 files with same AWS account ID)
# Edit infra/env/dev/env.env and update:
#   - aws_account_id = "YOUR_AWS_ACCOUNT_ID" 
#   - gitops_repo_url = "https://github.com/YOUR_USERNAME/YOUR_REPO.git"

# 2. Bootstrap Terraform state backend  
cd bootstrap/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and update:
#   - aws_account_id = "YOUR_AWS_ACCOUNT_ID" (same as above)
terraform init && terraform apply

# 3. Deploy EKS cluster
cd ../infra/env/dev/eks-setup
terragrunt init && terragrunt apply
aws eks update-kubeconfig --region YOUR_REGION --name us-mobile-challenge-dev

# 4. Deploy ArgoCD
cd ../argocd
terragrunt init && terragrunt apply

# 5. Get URLs
cd ../../../..
./get-urls.sh
```

### Manual Teardown

```bash
# Destroy ArgoCD first
cd infra/env/dev/argocd
terragrunt destroy

# Destroy EKS cluster
cd ../eks-setup
terragrunt destroy

# Destroy bootstrap (optional - keeps state history)
cd ../../../bootstrap
terraform destroy
```

## GitOps Blue/Green Deployment Workflow

**Simple GitOps workflow - update Helm values to trigger deployments:**

> **Note on CI Pipeline:** This demo uses pre-built Docker images (`hodgesarolin/clippy-maze-x86_64:v1.0.0`, `v2.0.0`, `v2.0.1`) to focus on the GitOps deployment workflow. In a real environment, you'd have GitHub Actions or similar CI building new images from app code changes. Since the application is already containerized and staged, we demonstrate the CD (Continuous Deployment) portion by updating Helm values to trigger blue/green deployments.

```bash
# 1. Check current version and get URLs
./get-urls.sh
# Access stable URL - should show current version

# 2. Deploy new version to Green environment
# Edit charts/clippy-maze/values.yaml and change tag: v1.0.0 to tag: v2.0.1
git commit -am "Deploy v2.0.1 to Green" && git push

# 3. ArgoCD automatically detects change and starts deployment
# Green environment deploys and runs health checks
kubectl get rollouts -n default -w

# 4. Test Green environment using preview URL
./get-urls.sh  # Get both Blue and Green URLs
# Compare both versions side-by-side

# 5. Automatic promotion (if health checks pass)
# The system automatically promotes Green to Blue after health checks succeed
# No manual intervention required - traffic switches automatically
```

### Demo Scenarios

**Test failure scenarios with automated rollback:**
```bash
# Deploy broken version (existing broken image)
sed -i 's/tag: v1.0.0/tag: v2.0.0/' charts/clippy-maze/values.yaml
git commit -am "Deploy broken v2.0.0" && git push

# Watch automatic rollback in action
kubectl get rollouts -n default -w
# Green environment fails health checks and auto-rolls back
# Blue continues serving traffic throughout

# Manual abort if needed
kubectl argo rollouts abort clippy-maze -n default
```

### **Key Benefits:**
- **GitOps Automation** - Git commit triggers deployment via ArgoCD
- **Zero-pressure testing** - Green runs independently  
- **Automated rollback** - Failed deployments roll back automatically
- **Automatic promotion** - Healthy deployments promote automatically after health checks
- **Team validation** - Multiple people can test Green during health check period
- **Real traffic comparison** - Both environments handle real requests

## Prerequisites

**Required Tools:**
```bash
# macOS
brew install awscli kubectl helm terraform terragrunt docker

# Ubuntu/Debian  
sudo snap install kubectl helm
# + install terraform, terragrunt, docker manually

# Windows
choco install awscli kubectl helm terraform terragrunt docker-desktop
```

**AWS Setup:**
```bash
# Configure AWS credentials with admin access
aws configure

# Verify access
aws sts get-caller-identity
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   GitHub Repo   │    │   AWS EKS      │
│                 │    │                 │    │                 │
│  1. Code Change │───▶│  2. Git Commit  │───▶│  3. ArgoCD Sync │
│  2. Image Build │    │     (GitOps)    │    │     (Deploy)    │
│  3. Tag Update  │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
┌─────────────────────────────────────────────────────▼─────────────┐
│                     AWS EKS Cluster                                │
│                                                                    │
│  ┌─────────────┐  ┌─────────────────────────────────────────────┐ │
│  │   ArgoCD    │  │              Argo Rollouts                  │ │
│  │             │  │                                             │ │
│  │ • Monitors  │  │  Blue (Stable)        Green (Preview)      │ │
│  │   Git Repo  │  │  ┌─────────────┐    ┌─────────────────┐   │ │
│  │ • Syncs     │  │  │ Clippy v1.0 │    │  Clippy v2.0    │   │ │
│  │   Changes   │  │  │   (Active)  │    │  (Testing)      │   │ │
│  │ • Triggers  │  │  └─────────────┘    └─────────────────┘   │ │
│  │   Rollouts  │  │         │                     │           │ │
│  └─────────────┘  │         ▼                     ▼           │ │
│                   │  ┌─────────────┐    ┌─────────────────┐   │ │
│                   │  │   ALB       │    │   ALB Preview   │   │ │
│                   │  │ (Production)│    │   (Testing)     │   │ │
│                   │  └─────────────┘    └─────────────────┘   │ │
│                   └─────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

## URLs & Access Points

After deployment, you'll have these endpoints:

| Service | URL | Purpose |
|---------|-----|---------|
| **Clippy Game (Stable)** | `./get-urls.sh` | Production game version |
| **Clippy Game (Preview)** | `./get-urls.sh` | Blue/green testing version |
| **ArgoCD Dashboard** | `kubectl port-forward svc/argocd-server -n argocd 8080:443` | GitOps management |
| **Rollouts Dashboard** | `kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100` | Deployment monitoring |

## True Blue/Green Deployment Flow

1. **Developer commits** code change to Git
2. **ArgoCD detects** change and creates **Green environment**  
3. **Deployment pauses** - waiting for manual promotion
4. **Test Green environment** using preview URL
5. **Manual promotion** - you decide when to switch traffic
6. **Traffic switches** Blue → Green instantly
7. **Old Blue** environment gets cleaned up after delay

**Manual Control Commands:**
```bash
# Promote to Green (switch traffic)
kubectl argo rollouts promote clippy-maze -n default

# Abort rollout (keep Blue active)
kubectl argo rollouts abort clippy-maze -n default

# Watch rollout status
kubectl get rollouts -n default -w
```

**Both environments run simultaneously:**
- **Blue (Stable)**: `./get-urls.sh` → Stable URL (current production)
- **Green (Preview)**: `./get-urls.sh` → Preview URL (new version testing)

## Manual Step-by-Step Deployment

Manual deployment steps:

### Step 1: Bootstrap (One-time)
```bash
cd bootstrap/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS account details
terraform init && terraform apply
```

### Step 2: Deploy EKS
```bash
cd ../infra/env/dev/eks-setup
terragrunt init && terragrunt apply
aws eks update-kubeconfig --region us-east-1 --name us-mobile-challenge-dev
```

### Step 3: Deploy ArgoCD
```bash
cd ../argocd  
terragrunt init && terragrunt apply
```

### Step 4: Get Access URLs
```bash
./get-urls.sh
# Get ArgoCD password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Repository Structure

```
us_mobile_challange/
├── get-urls.sh                  # Get all URLs quickly
├── README.md                    # Complete documentation
│
├── infra/                      # Infrastructure as Code
│   ├── modules/                   # Reusable Terraform modules
│   │   ├── vpc/                  # VPC + subnets + NAT  
│   │   ├── eks-setup/            # EKS cluster + nodes
│   │   ├── addons/               # ArgoCD + Load Balancer Controller
│   │   └── irsa/                 # IAM Roles for Service Accounts
│   └── env/dev/                  # Environment configs
│       ├── eks-setup/            # EKS deployment
│       └── argocd/               # ArgoCD deployment
│
├── charts/                     # Helm charts
│   └── clippy-maze/              # Application Helm chart
│       ├── Chart.yaml            # Chart metadata
│       ├── values.yaml           # Default values + image tags
│       └── templates/            # Kubernetes templates
│           ├── rollout.yaml      # Blue/green deployment config
│           ├── services.yaml     # Stable + Preview services
│           ├── ingress.yaml      # ALB ingress configs
│           └── analysis.yaml     # Automated rollback templates
│
├── gitops/                     # GitOps manifests (ArgoCD managed)
│   └── clusters/dev/             # Cluster-specific configurations
│       ├── apps/                 # Application deployments
│       └── system/               # System configurations
│
└── bootstrap/                  # Terraform state setup
    ├── main.tf                   # S3 backend + DynamoDB locks
    └── terraform.tfvars.example  # AWS account configuration
```

## Configuration

### Minimal Configuration ✨

**Edit just your AWS account ID in 2 files:**
1. `infra/env/dev/env.env` (+ GitHub repo URL)  
2. `bootstrap/terraform.tfvars` (+ same AWS account ID)

Everything else uses sensible defaults.

**You only need to update 2 values:**

```hcl
locals {
  # AWS Configuration - UPDATE THESE 2 VALUES
  aws_account_id  = "123456789012"  # CHANGE: Your AWS account ID
  gitops_repo_url = "https://github.com/YOUR_USERNAME/YOUR_REPO.git"  # CHANGE: Your fork URL
  
  # Defaults (change if needed)
  aws_region      = "us-east-1"
  
  # Everything else is automatically configured
  cluster_name = "us-mobile-challenge-dev"
  # ... rest of configuration
}
```

### Other Available Settings (Optional)

Additional settings in `infra/env/dev/env.env` you can customize:

| Variable | Description | Default | 
|----------|-------------|---------|
| `cluster_name` | EKS cluster name | `us-mobile-challenge-dev` |
| `instance_type` | Worker node type | `t3.medium` |
| `desired_size` | Initial node count | `2` |
| `capacity_type` | Instance pricing | `SPOT` (cost-optimized) |
| `domain_base` | Custom domain (optional) | `""` (none) |

## Security Features

- **IRSA (IAM Roles for Service Accounts)** - No static AWS keys
- **Network Policies** - Namespace isolation
- **RBAC** - Read-only access for reviewers  
- **AppProject** - Restricted repository access
- **Least Privilege** - Minimal IAM permissions

## Cost Optimization

### Estimated Monthly Costs
- **EKS Control Plane**: $72/month
- **EC2 Spot Instances** (2x t3.medium): ~$20/month  
- **ALB**: ~$18/month
- **NAT Gateway**: ~$32/month
- **EBS Storage**: ~$8/month
- **Total**: ~$150/month

### Cost Savings Built-in
- **Spot Instances** - Up to 90% savings vs On-Demand
- **Right-sizing** - t3.medium nodes (sufficient for demo)
- **Auto-scaling** - Scale down when not needed

### Complete Teardown (Avoid Charges!)

**Destroy in reverse order:**
```bash
# 1. Destroy ArgoCD first
cd infra/env/dev/argocd
terragrunt destroy

# 2. Destroy EKS cluster  
cd ../eks-setup
terragrunt destroy

# 3. Destroy state backend (optional)
cd ../../../bootstrap
terraform destroy
```

**If resources get stuck:**
```bash
# Manual ALB cleanup (common issue)
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(to_string(Tags), `us-mobile-challenge-dev`)].[LoadBalancerArn,LoadBalancerName]'
aws elbv2 delete-load-balancer --load-balancer-arn <ALB_ARN>

# Then retry terragrunt destroy
```

**Verify cleanup:**
```bash
# Check for any remaining resources
aws eks describe-cluster --name us-mobile-challenge-dev 2>/dev/null || echo "✅ Cluster deleted"
aws elbv2 describe-load-balancers --query 'LoadBalancers[?VpcId==`<VPC_ID>`]' || echo "✅ ALBs deleted"
```

## Troubleshooting

### Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| **EKS access denied** | `aws eks update-kubeconfig --region us-east-1 --name us-mobile-challenge-dev` |
| **ArgoCD sync fails** | Check repo access: `kubectl get applications -n argocd` |
| **ALB not created** | Verify Load Balancer Controller: `kubectl get pods -n kube-system` |
| **Game URL 404** | Wait for ALB provisioning: `kubectl get ingress -n default` |
| **High AWS costs** | Follow teardown steps in Cost Optimization section above |

### Useful Commands

```bash
# Debug cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Monitor applications  
kubectl get applications -n argocd
kubectl get rollouts -n default -w

# Check networking
kubectl get ingress --all-namespaces
kubectl get services --all-namespaces

# View logs
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Production Considerations

This is a **demonstration environment**. For production:

- **Multi-repo GitOps** - Separate infra/config/app repositories
- **Secrets Management** - AWS Secrets Manager + External Secrets Operator
- **Observability** - Prometheus + Grafana + Jaeger tracing
- **Security** - Private subnets + VPN access + security scanning
- **Backup/DR** - EBS snapshots + cross-region replication
- **Multi-environment** - Dev/staging/prod with promotion pipelines

## License

MIT License - Feel free to use this for learning and demonstration purposes.

## Contributing

PRs welcome! This project demonstrates GitOps best practices and modern cloud-native deployment patterns.

---

**Happy GitOpsing!** Deploy with confidence using blue/green deployments and automated rollbacks.
