output "namespace" {
  description = "the kubernetes namespace of the release"
  value       = helm_release.argocd.namespace
}

output "release_name" {
  description = "the name of the release"
  value       = helm_release.argocd.name
}
