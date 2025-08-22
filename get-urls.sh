#!/bin/bash

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Clippy Maze Game URLs:"
echo "=============================="

# Get current game URLs from Kubernetes
if kubectl get ingress clippy-maze-stable -n default &> /dev/null; then
  STABLE_URL="http://$(kubectl get ingress clippy-maze-stable -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
  PREVIEW_URL="http://$(kubectl get ingress clippy-maze-preview -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
  
  echo -e "${BLUE}Blue (Stable):${NC}   $STABLE_URL"
  echo -e "${GREEN}Green (Preview):${NC} $PREVIEW_URL"
else
  echo "Game not deployed yet. Run 'terragrunt apply' first."
fi

echo ""
echo "Management URLs:"
echo "=============================="

# Get ArgoCD URL
if kubectl get svc argocd-server -n argocd &> /dev/null; then
  ARGOCD_HOSTNAME=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  if [ -n "$ARGOCD_HOSTNAME" ]; then
    echo "ArgoCD:   http://$ARGOCD_HOSTNAME"
  else
    echo "ArgoCD:   https://localhost:8080 (use: kubectl port-forward svc/argocd-server -n argocd 8080:443)"
  fi
else
  echo "ArgoCD not deployed yet."
fi

# Get Rollouts Dashboard URL
if kubectl get svc argo-rollouts-dashboard -n argo-rollouts &> /dev/null; then
  echo "Rollouts: kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100"
else
  echo "Rollouts Dashboard not deployed yet."
fi

echo ""
echo "Get ArgoCD Password:"
echo "=============================="
echo 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d'

echo ""
echo "Quick Commands:"
echo "=============================="
echo "• Watch rollouts: kubectl get rollouts -n default -w"
echo "• Watch pods:     kubectl get pods -n default -w"
echo "• ArgoCD apps:    kubectl get applications -n argocd"