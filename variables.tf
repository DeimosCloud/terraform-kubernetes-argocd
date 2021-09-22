variable "namespace" {
  default     = "argocd"
  description = "The namespace to deploy argocd into"
}

variable "repositories" {
  description = "A list of repository defintions"
  #  default = [
  #    {
  #      url= "https:repo"
  #      username= "foo"
  #      ssh_key= "RSA-bar"
  #    },
  #    {
  #      url= "https:repo"
  #      access_token = "bar"
  #    },
  #    {
  #      url  = "https://charts.jetstack.io"
  #      type = "helm"
  #    },
  #  ]
  default = []
  type    = list(map(string))
}

variable "chart_version" {
  description = "version of charts"
  default     = null
}

variable "module_depends_on" {
  description = "resources that the module depends on, aks, namespace creation etc"
  default     = null
}


variable "server_extra_args" {
  description = "Extra arguments passed to argoCD server"
  default     = []
}

variable "server_insecure" {
  description = "Whether to run the argocd-server with --insecure flag. Useful when disabling argocd-server tls default protocols to provide your certificates"
  default     = false
}

variable "ingress_tls_secret" {
  description = "The TLS secret name for argocd ingress"
  default     = "argocd-server-tls"
}

variable "ingress_host" {
  description = "The ingress host"
  default     = null
}

variable "ingress_annotations" {
  description = "annotations to pass to the ingress"
  default     = {}
  #  default = {
  #    "kubernetes.io/ingress.class"                    = "nginx"
  #    "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
  #    "nginx.ingress.kubernetes.io/ssl-passthrough"    = "true"
  #    "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
  #    "kubernetes.io/tls-acme"                         = "true"
  #    "cert-manager.io/cluster-issuer"                 = "lets-encrypt"
  #  }
}
