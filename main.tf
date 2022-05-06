terraform {
  required_version = ">= 0.13"

  required_providers {
    helm       = ">=1.2.3"
    kubernetes = ">=2.10.0"
    google     = ">=4.19.0"

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

locals {
  # extra_manifests = join(" ", var.manifests)

  secret_name = "argocd-repository-credentials"

  # Get list of all keys for secrets
  secret_keys = [
    for i, repo in var.repositories :
    ["username-${i}", "password-${i}", "sshkey-${i}", ]
  ]

  # Get values for each key
  secret_values = [
    for repo in var.repositories :
    [
      lookup(repo, "username", lookup(repo, "access_token", null) != null ? "argocd" : null),
      lookup(repo, "password", lookup(repo, "access_token", null)),
      lookup(repo, "password", lookup(repo, "ssh_key", null))
    ]
  ]

  # Delete keys with empty values
  secrets = {
    for key, value in zipmap(flatten(local.secret_keys), flatten(local.secret_values)) :
    key => value if value != null
  }

  # construct a map of repositories in format
  # {
  # type         = repoType
  # url            = repoURL
  # usernameSecret = usernameSecret
  # passwordSecret = passwordSecret
  # sshSecret      = sshSecret
  # }

  all_repositories = [
    for i, repo in var.repositories : {
      type = lookup(repo, "type", null)
      url  = repo.url
      usernameSecret = lookup(repo, "username", lookup(repo, "access_token", null) != null ? "argocd" : null) == null ? null : {
        key  = "username-${i}"
        name = local.secret_name
      }
      passwordSecret = lookup(repo, "password", lookup(repo, "access_token", null)) == null ? null : {
        key  = "password-${i}"
        name = local.secret_name
      }
      sshSecret = lookup(repo, "password", lookup(repo, "ssh_key", null)) == null ? null : {
        key  = "sshkey-${i}"
        name = local.secret_name
      }
    }
  ]

  # Remove map keys from all_repositories with no value. That means they were not specified
  clean_repositories = [
    for repo in local.all_repositories : {
      for k, v in repo : k => v if v != null
    }
  ]

  # If no_auth_config has been specified, set all configs as null
  values = merge({
    global = {
      image = {
        tag = var.image_tag
      }
    }

    server = {
      config = merge({
        # Configmaps require strings, yamlencode the map
        repositories = yamlencode(local.clean_repositories)
      }, var.config)
      rbacConfig = var.rbac_config
      # Run insecure mode if specified, to prevent argocd from using it's own certificate
      extraArgs = var.server_insecure ? ["--insecure"] : null
      # Ingress Values
      ingress = {
        enabled     = var.ingress_host != null ? true : false
        https       = true
        annotations = var.ingress_annotations
        hosts       = [var.ingress_host]
        tls = var.server_insecure ? [{
          secretName = var.ingress_tls_secret
          hosts      = [var.ingress_host]
        }] : null
      }
    }
    configs = {
      repositoryCredentials = local.secrets
    }
  })
}

# ArgoCD Charts
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  # force_update = true
  # dependency_update = true

  values = [yamlencode(local.values), yamlencode(var.values)]
}

data "kubectl_path_documents" "docs" {
  pattern = "${var.manifests}/*.yaml"
}

resource "kubectl_manifest" "extra_manifests" {
  for_each  = toset(data.kubectl_path_documents.docs.documents)
  yaml_body = each.value

  depends_on = [helm_release.argocd]
}

