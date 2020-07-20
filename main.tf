locals {
  # Use this to know if any auth method has been specified
  # True if no config has been specified and in such a case server.config.repositories will be null
  no_auth_config = var.git_ssh_key == null && var.git_username == null && var.git_access_token == null

  secret_name         = "argocd-repository-credentials"
  ssh_secret_key      = "ssh"
  username_secret_key = "username"
  password_secret_key = "password"


  # For SSH Key authentications
  config_map = {
    url = var.git_url
  }

  ssh_config_map = {
    sshPrivateKeySecret = {
      name = local.secret_name
      key  = local.ssh_secret_key
    }
  }

  username_config_map = {
    usernameSecret = {
      name = local.secret_name
      key  = local.username_secret_key
    }
    passwordSecret = {
      name = local.secret_name
      key  = local.password_secret_key
    }
  }


  # Secret for ssh
  ssh_secret = {
    "${local.ssh_secret_key}" = var.git_ssh_key
  }

  # Secret for Username/password
  # If access token is provided, the username can be any string with the access token as password
  # https://argoproj.github.io/argo-cd/user-guide/private-repositories/#access-token
  username_secret = {
    "${local.username_secret_key}" = var.git_access_token == null ? var.git_username : "argocd"
    "${local.password_secret_key}" = var.git_access_token == null ? var.git_password : var.git_access_token
  }

  # Authentication can be using username or SSH Keys. If sshkey is not specified it should default to username/password
  # This will not still be used unless local.no_auth_config is false
  auth_config_map = var.git_ssh_key == null ? local.username_config_map : local.ssh_config_map
  auth_secret     = var.git_ssh_key == null ? local.username_secret : local.ssh_secret

  # If no_auth_config has been specified, set all configs as null
  values = {
    server = {
      config = {
        # Configmaps require strings, yamlencode the map
        repositories = yamlencode(local.no_auth_config ? null : [merge(local.config_map, local.auth_config_map)])
      }
      # Run insecure mode if specified, to prevent argocd from using it's own certificate
      extraArgs = var.server_insecure ? ["--insecure"] : null
      # Ingress Values
      ingress = {
        enabled     = var.ingress_host != null ? true : false
        https       = true
        annotations = var.ingress_annotations
        hosts       = [var.ingress_host]
        tls = [{
          secretName = var.ingress_tls_secret
          hosts      = [var.ingress_host]
        }]
      }
    }
    configs = {
      repositoryCredentials = local.no_auth_config ? null : local.auth_secret
    }
  }
}

# ArgoCD Charts
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values     = [yamlencode(local.values)]
  depends_on = [var.module_depends_on]
}
