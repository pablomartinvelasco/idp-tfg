#!/usr/bin/env bash
# Etapa 2 del bootstrap (ADR-0003): Argo CD y la Application raíz mediante Terraform
# (infra/terraform/bootstrap). Después espera a que Argo CD sincronice gitops/platform.
# Uso: bootstrap.sh up | plan | password

source "$(dirname "$0")/lib.sh"
require terraform kubectl

TF_DIR="${REPO_ROOT}/infra/terraform/bootstrap"
tf() { terraform -chdir="${TF_DIR}" "$@"; }

require_cluster() {
  [[ -f "${KUBECONFIG}" ]] || die "no existe ${KUBECONFIG}: crea antes el clúster (make up)."
}

# La raíz crea las Applications de plataforma; cada una debe quedar Synced y Healthy.
wait_platform() {
  local -a apps
  log "Esperando a que Argo CD sincronice gitops/platform (${LAB_GITOPS_REPO}@${LAB_GITOPS_REVISION})"
  kc wait application/root -n argocd --for=jsonpath='{.status.sync.status}'=Synced --timeout=300s >/dev/null
  mapfile -t apps < <(kc get applications -n argocd -o name)
  kc wait "${apps[@]}" -n argocd --for=jsonpath='{.status.sync.status}'=Synced --timeout=600s
  kc wait "${apps[@]}" -n argocd --for=jsonpath='{.status.health.status}'=Healthy --timeout=600s
}

case "${1:-}" in
  plan)
    if [[ ! -f "${KUBECONFIG}" ]]; then
      warn "sin clúster: se omite el plan de ${TF_DIR#"${REPO_ROOT}"/}"
      exit 0
    fi
    tf init -input=false >/dev/null
    tf plan -input=false
    ;;
  up)
    require_cluster
    log "terraform apply (${TF_DIR#"${REPO_ROOT}"/})"
    tf init -input=false >/dev/null
    tf apply -input=false -auto-approve
    wait_platform
    log "Argo CD: $(tf output -raw argocd_url) · usuario admin · contraseña: make argocd-password"
    ;;
  password)
    require_cluster
    kc get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
    printf '\n'
    ;;
  *)
    die "uso: $0 up|plan|password"
    ;;
esac
