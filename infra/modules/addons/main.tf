terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.aws_load_balancer_controller_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

}

# ExternalDNS (optional - only if enabled and domain_base is provided)
resource "helm_release" "external_dns" {
  count = var.enable_external_dns && var.domain_base != "" ? 1 : 0

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.13.1"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.external_dns_role_arn
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set_list {
    name  = "domainFilters"
    value = [var.domain_base]
  }

  set {
    name  = "policy"
    value = "upsert-only"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "txtOwnerId"
    value = var.cluster_name
  }

}

# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "5.51.6"

  values = [yamlencode({
    global = {
      domain = var.domain_base != "" ? "${var.argocd_hostname}.${var.domain_base}" : ""
    }
    
    configs = {
      params = {
        "server.insecure" = true
      }
    }
    
    server = {
      service = {
        type = "LoadBalancer"
        annotations = merge({
          "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
        }, var.domain_base != "" ? {
          "external-dns.alpha.kubernetes.io/hostname" = "${var.argocd_hostname}.${var.domain_base}"
        } : {})
      }
      
      ingress = var.domain_base != "" ? {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class"                = "alb"
          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"      = "ip"
          "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
          "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
          "external-dns.alpha.kubernetes.io/hostname"  = "${var.argocd_hostname}.${var.domain_base}"
        }
        hosts = ["${var.argocd_hostname}.${var.domain_base}"]
        tls = [{
          hosts = ["${var.argocd_hostname}.${var.domain_base}"]
        }]
      } : {
        enabled = false
        annotations = {}
        hosts = []
        tls = []
      }
    }
    
    # Read-only user for reviewers
    configs = {
      rbac = {
        "policy.default" = "role:readonly"
        "policy.csv" = <<-EOF
          p, role:readonly, applications, get, *, allow
          p, role:readonly, applications, sync, *, allow
          p, role:readonly, repositories, get, *, allow
          p, role:readonly, clusters, get, *, allow
          g, reviewer, role:readonly
        EOF
      }
    }
  })]

  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.aws_load_balancer_controller
  ]
}


# Argo Rollouts Namespace
resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = "argo-rollouts"
  }
}

# Argo Rollouts
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  namespace  = "argo-rollouts"
  version    = "2.32.7"

  set {
    name  = "dashboard.enabled"
    value = "true"
  }

  set {
    name  = "dashboard.service.type"
    value = "LoadBalancer"
  }

  depends_on = [
    kubernetes_namespace.argo_rollouts,
    helm_release.aws_load_balancer_controller
  ]
}

# Argo Rollouts Dashboard Ingress (if domain provided and enabled)
resource "kubernetes_ingress_v1" "rollouts_dashboard" {
  count = var.domain_base != "" && var.enable_rollouts_dashboard_ingress ? 1 : 0

  metadata {
    name      = "rollouts-dashboard"
    namespace = "argo-rollouts"
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
      "external-dns.alpha.kubernetes.io/hostname"  = "${var.rollouts_dashboard_hostname}.${var.domain_base}"
    }
  }

  spec {
    rule {
      host = "${var.rollouts_dashboard_hostname}.${var.domain_base}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argo-rollouts-dashboard"
              port {
                number = 3100
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.argo_rollouts,
    helm_release.aws_load_balancer_controller
  ]
}

# ArgoCD Repository Secret for GitOps repo access (public repository)
resource "kubernetes_secret" "gitops_repo" {
  metadata {
    name      = "gitops-repo-public"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type = "git"
    url  = var.gitops_repo_url
  }

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# ArgoCD Application Project
resource "kubectl_manifest" "app_project" {
  count = var.create_argocd_application_project ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = var.app_project_name
      namespace = "argocd"
    }
    spec = {
      description = var.app_project_description
      
      sourceRepos = [var.gitops_repo_url]
      
      destinations = [{
        namespace = "*"
        server    = "https://kubernetes.default.svc"
      }]
      
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
      
      namespaceResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  })

  depends_on = [
    helm_release.argocd
  ]
}

# Root ArgoCD Application (App of Apps pattern)
resource "kubectl_manifest" "root_app" {
  count = var.create_argocd_application_project ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root"
      namespace = "argocd"
    }
    spec = {
      project = var.app_project_name
      
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = "HEAD"
        path           = "gitops/clusters/dev"
        directory = {
          recurse = true
        }
      }
      
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [
    kubectl_manifest.app_project,
    helm_release.argocd
  ]
}

# Clippy Maze Application manifest
resource "kubectl_manifest" "clippy_maze_app" {
  count = var.create_argocd_application_project ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "clippy-maze"
      namespace = "argocd"
    }
    spec = {
      project = var.app_project_name
      
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = "HEAD"
        path           = "charts/clippy-maze"
        helm = {
          valueFiles = ["values.yaml"]
        }
      }
      
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [
    kubectl_manifest.app_project,
    helm_release.argocd
  ]
}