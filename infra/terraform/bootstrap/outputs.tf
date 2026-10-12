output "argocd_url" {
  description = "URL de la interfaz de Argo CD (a través de Traefik)."
  value       = "http://${local.argocd_host}"
}

output "argocd_namespace" {
  description = "Namespace de Argo CD."
  value       = helm_release.argocd.namespace
}

output "argocd_version" {
  description = "Versión de Argo CD instalada (appVersion del chart)."
  value       = helm_release.argocd.metadata.app_version
}

output "gitops_source" {
  description = "Repositorio y revisión que sincroniza la Application raíz."
  value       = "${var.gitops_repo_url}@${var.gitops_revision}"
}
