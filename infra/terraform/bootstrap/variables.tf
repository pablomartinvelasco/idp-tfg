variable "kubeconfig_path" {
  description = "Kubeconfig del laboratorio generado por la etapa cluster."
  type        = string
}

variable "kube_context" {
  description = "Contexto kubectl del clúster (kind-<cluster_name>)."
  type        = string
  default     = "kind-idp-lab"
}

variable "domain" {
  description = "Dominio base de las URLs del laboratorio. Argo CD se publica en argocd.<domain>."
  type        = string
  default     = "localtest.me"
}

variable "gitops_repo_url" {
  description = "Repositorio Git que lee Argo CD. Es público: no se configuran credenciales (RNF-04)."
  type        = string

  validation {
    condition     = can(regex("^https://", var.gitops_repo_url))
    error_message = "gitops_repo_url debe ser una URL https:// de solo lectura."
  }
}

variable "gitops_revision" {
  description = "Rama o etiqueta desde la que se sincroniza la Application raíz."
  type        = string
  default     = "main"
}

variable "argocd_chart_version" {
  description = "Versión del chart argo-cd. Se inyecta desde versions.env (ARGOCD_CHART_VERSION)."
  type        = string
}

variable "argocd_apps_chart_version" {
  description = "Versión del chart argocd-apps. Se inyecta desde versions.env (ARGOCD_APPS_CHART_VERSION)."
  type        = string
}
