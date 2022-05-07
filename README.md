# Terraform-argocd
Setup ArgoCD on cluster using terraform. Ensure the `kubernetes` provider configuration and `helm` provider configuration works fine

## Usage


### Argocd with Nginx Ingress Controller
```hcl

locals {
  # Example annotations when using Nginx ingress controller as shown here https://argoproj.github.io/argo-cd/operator-manual/ingress/#option-1-ssl-passthrough
  argocd_ingress_annotations = {
    "kubernetes.io/ingress.class" = nginx
    "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
  }
  argocd_repositories = [
    {
      url          = "https://repo.git"
      username = "hello"
      password = "bar"
    },
    {
      url          = "https://repo.git"
      access_token = var.argocd_access_token
    },
    {
      url  = "https://charts.jetstack.io"
      type = "helm"
    },
  ]

}

module "argocd" {
  source              = "https://gitlab.com/deimosdev/tooling/terraform-modules/terraform-kubernetes-argocd"
  ingress_host        = "argocd.example.com"
  ingress_annotations = local.argocd_ingress_annotations
  repositories        = local.argocd_repositories
  # Argocd Config
  config = {
    "accounts.image-updater" = "apiKey"
  }

  # Argocd RBAC Config
  rbac_config = {
    "policy.default" = "role:readonly"
    "policy.csv"     = <<POLICY
  p, role:image-updater, applications, get, */*, allow
  p, role:image-updater, applications, update, */*, allow
  g, image-updater, role:image-updater
POLICY
  }

  module_depends_on = [module.gke]
}
```

### Argocd with Azure Application Gateway Ingress Controller
```hcl
locals {
  # Example annotations when using Azure application gateway Ingress Controller with Cert-manager
  argocd_ingress_annotations = {
    "cert-manager.io/cluster-issuer"           = module.cert_manager.issuer
    "appgw.ingress.kubernetes.io/ssl-redirect" = "true"
    "kubernetes.io/ingress.class"              = "azure/application-gateway"
  }
}

module "argocd" {
  source              = "https://gitlab.com/deimosdev/tooling/terraform-modules/terraform-kubernetes-argocd"
  repositories        = local.argocd_repositories
  ingress_host        = "argocd.${var.dns_zone_name}"
  ingress_annotations = local.argocd_ingress_annotations
  server_insecure     = true # Run argocd-server in secure mode to prevent SSL conflicts with application/gateway and cert-manager

  module_depends_on = [module.gke]
}
```

Ensure Kubernetes Provider and Helm Provider settings are correct https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started#provider-setup

## Contributing

Report issues/questions/feature requests on in the issues section.

Full contributing guidelines are covered [here](CONTRIBUTING.md).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >=4.19.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >=1.2.3 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >=2.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.5.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.extra_manifests](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_path_documents.docs](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/path_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | version of charts | `string` | `">=4.5.10"` | no |
| <a name="input_config"></a> [config](#input\_config) | Additional config to be added to the Argocd configmap | `map` | `{}` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag to install | `string` | `null` | no |
| <a name="input_ingress_annotations"></a> [ingress\_annotations](#input\_ingress\_annotations) | annotations to pass to the ingress | `map` | `{}` | no |
| <a name="input_ingress_host"></a> [ingress\_host](#input\_ingress\_host) | The ingress host | `any` | `null` | no |
| <a name="input_ingress_tls_secret"></a> [ingress\_tls\_secret](#input\_ingress\_tls\_secret) | The TLS secret name for argocd ingress | `string` | `"argocd-tls"` | no |
| <a name="input_manifests_directory"></a> [manifests\_directory](#input\_manifests\_directory) | Path/URL to directory that contains manifest files to be applied after argocd is deployed | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace to deploy argocd into | `string` | `"argocd"` | no |
| <a name="input_rbac_config"></a> [rbac\_config](#input\_rbac\_config) | Additional rbac config to be added to the Argocd rbac configmap | `map` | `{}` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | A list of repository defintions | `list(map(string))` | `[]` | no |
| <a name="input_server_extra_args"></a> [server\_extra\_args](#input\_server\_extra\_args) | Extra arguments passed to argoCD server | `list` | `[]` | no |
| <a name="input_server_insecure"></a> [server\_insecure](#input\_server\_insecure) | Whether to run the argocd-server with --insecure flag. Useful when disabling argocd-server tls default protocols to provide your certificates | `bool` | `false` | no |
| <a name="input_values"></a> [values](#input\_values) | Extra Values to pass to the Argocd Helm Deployment | `map` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | the kubernetes namespace of the release |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | the name of the release |
| <a name="output_server_url"></a> [server\_url](#output\_server\_url) | The server URL of argocd created by ingress |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
