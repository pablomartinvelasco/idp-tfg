#!/usr/bin/env bash
# Ciclo de vida del clúster kind mediante Terraform (infra/terraform/cluster).
# Uso: cluster.sh up | plan | down | status

source "$(dirname "$0")/lib.sh"
require terraform kubectl

TF_DIR="${REPO_ROOT}/infra/terraform/cluster"
tf() { terraform -chdir="${TF_DIR}" "$@"; }

case "${1:-}" in
  plan)
    tf init -input=false >/dev/null
    tf plan -input=false
    ;;
  up)
    "${REPO_ROOT}/scripts/preflight.sh"
    mkdir -p "$(dirname "${KUBECONFIG}")"
    log "terraform apply (${TF_DIR#"${REPO_ROOT}"/})"
    tf init -input=false >/dev/null
    tf apply -input=false -auto-approve
    chmod 600 "${KUBECONFIG}"
    log "Clúster listo. Para usar kubectl fuera de make: export KUBECONFIG=${KUBECONFIG}"
    ;;
  down)
    log "terraform destroy: se eliminará el clúster '${LAB_CLUSTER_NAME}' y todo su contenido"
    tf init -input=false >/dev/null
    tf destroy -input=false -auto-approve
    ;;
  status)
    if kind get clusters 2>/dev/null | grep -qx "${LAB_CLUSTER_NAME}"; then
      ok "clúster '${LAB_CLUSTER_NAME}' en ejecución"
      kc get nodes -o wide
    else
      warn "clúster '${LAB_CLUSTER_NAME}' no encontrado"
    fi
    ;;
  *)
    die "uso: $0 up|plan|down|status"
    ;;
esac
