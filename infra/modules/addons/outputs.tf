output "argocd_server_url" {
  description = "ArgoCD server URL"
  value = var.domain_base != "" ? "https://argo.${var.domain_base}" : "kubectl port-forward svc/argocd-server -n argocd 8080:443"
}

output "rollouts_dashboard_url" {
  description = "Argo Rollouts dashboard URL"
  value = var.domain_base != "" ? "https://clippy-status.${var.domain_base}" : "kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100"
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "clippy_game_stable_url" {
  description = "Clippy Maze game stable URL (main production version)"
  value = var.domain_base != "" ? "https://clippy.${var.domain_base}" : "kubectl get ingress clippy-stable -n default -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}'"
}

output "clippy_game_preview_url" {
  description = "Clippy Maze game preview URL (blue/green testing version)"
  value = var.domain_base != "" ? "https://clippy-preview.${var.domain_base}" : "kubectl get ingress clippy-preview -n default -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}'"
}

output "clippy_game_urls_command" {
  description = "Command to get current Clippy game URLs"
  value = "kubectl get ingress -n default -o custom-columns='SERVICE:metadata.name,URL:status.loadBalancer.ingress[0].hostname' --no-headers | sed 's/^/http:\\/\\//' | sed 's/\\s\\+/ → http:\\/\\//'"
}