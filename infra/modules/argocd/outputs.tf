output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = module.addons.argocd_server_url
}

output "rollouts_dashboard_url" {
  description = "Argo Rollouts dashboard URL"
  value       = module.addons.rollouts_dashboard_url
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = module.addons.argocd_admin_password_command
}

output "demo_instructions" {
  description = "Instructions for blue/green deployment demo"
  value = <<EOF
✅ GitOps Platform Deployment Complete!

## Access ArgoCD:
1. Get ArgoCD LoadBalancer URL:
   kubectl get svc -n argocd argocd-server

2. Get ArgoCD admin password:
   ${module.addons.argocd_admin_password_command}

3. Login to ArgoCD with admin/<password>

## Blue/Green Deployment Demo:
1. The clippy-maze application is configured for blue/green deployments
2. Update the image tag in gitops/apps/clippy-maze/rollout.yaml
3. Available Docker images:
   - hodgesarolin/clippy-maze:v1.0.0 (baseline)
   - hodgesarolin/clippy-maze:v2.0.0 (broken - fails health checks)  
   - hodgesarolin/clippy-maze:v2.0.1 (improved with real Clippy)

## Test Blue/Green Process:
1. Update rollout.yaml to use v2.0.0 (broken version)
2. Git commit + push to YOUR fork
3. Watch deployment FAIL in ArgoCD UI
4. See automatic rollback to previous version
5. Update to v2.0.1 (working version)
6. Watch successful deployment and manual promotion

Note: Make sure you're pushing changes to YOUR fork of the repository!
EOF
}