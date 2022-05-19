terraform {
  required_version = ">= 0.14"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=1.2.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
  experiments = [module_variable_optional_attrs]

}
