variable "namespace" {
  default     = "argocd"
  description = "The namespace to deploy argocd into"
}

variable "git_ssh_key" {
  description = "sshkey for authentication"
  default     = null
}

variable "git_access_token" {
  description = "An Optional Access Token for git authentication"
  default     = null
}
variable "git_username" {
  description = "Username for authentication"
  default     = null
}

variable "git_password" {
  description = "The password for the user"
  default     = null
}

variable "git_url" {
  description = "the url of the git repo to authenticate to"
}

variable "chart_version" {
  description = "version of charts"
  default     = "2.5.4"
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
}
