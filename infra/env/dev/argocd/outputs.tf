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

output "clippy_game_stable_url" {
  description = "Clippy Maze game stable URL (main production version)"
  value       = module.addons.clippy_game_stable_url
}

output "clippy_game_preview_url" {
  description = "Clippy Maze game preview URL (blue/green testing version)"
  value       = module.addons.clippy_game_preview_url
}

output "clippy_game_urls_command" {
  description = "Command to get current Clippy game URLs"
  value       = module.addons.clippy_game_urls_command
}

output "setup_complete_message" {
  description = "Setup completion message with all URLs"
  value = <<EOT
GitOps EKS Setup Complete!

Clippy Maze Game URLs:
- Stable:  ${module.addons.clippy_game_stable_url}
- Preview: ${module.addons.clippy_game_preview_url}

Management URLs:
- ArgoCD:  ${module.addons.argocd_server_url}
- Rollouts: ${module.addons.rollouts_dashboard_url}

Next Steps:
1. Get ArgoCD password: ${module.addons.argocd_admin_password_command}
2. Access game URLs above
3. Make changes to gitops/ folder to trigger deployments
4. Monitor blue/green deployments in ArgoCD and Rollouts Dashboard

Demo Blue/Green:
- Update image tag in gitops/apps/clippy-maze/rollout.yaml
- Commit & push changes
- Watch deployment in ArgoCD

EOT
}