# Etapa 2 del bootstrap (ADR-0003): instala Argo CD y le entrega la Application raíz.
#
# Responsabilidad de este módulo: los releases `argocd` y `argocd-apps` y nada más. Lo que
# cuelga de la Application raíz (Traefik, namespaces de entorno, etc.) lo gestiona Argo CD
# desde gitops/platform. Argo CD no se autogestiona: su versión y sus valores cambian aquí.

locals {
  argocd_namespace = "argocd"
  argocd_host      = "argocd.${var.domain}"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = local.argocd_namespace
  create_namespace = true

  # Espera a que los Deployments estén listos: argocd-apps necesita las CRDs y el controlador.
  wait    = true
  timeout = 600

  values = [
    templatefile("${path.module}/values/argocd.yaml.tftpl", {
      host = local.argocd_host
    }),
  ]
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version
  # La referencia al release anterior establece el orden de creación.
  namespace = helm_release.argocd.namespace

  values = [
    templatefile("${path.module}/values/argocd-apps.yaml.tftpl", {
      namespace       = helm_release.argocd.namespace
      gitops_repo_url = var.gitops_repo_url
      gitops_revision = var.gitops_revision
    }),
  ]
}
