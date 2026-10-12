# shellcheck shell=bash
# Funciones y entorno comunes. Se carga con `source` desde el resto de scripts.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# Versiones fijadas (fuente única).
# shellcheck source=../versions.env
source "${REPO_ROOT}/versions.env"

# Configuración local opcional (.env, excluido de Git). Los valores ya exportados en el
# entorno tienen prioridad sobre los del fichero.
if [[ -f "${REPO_ROOT}/.env" ]]; then
  while IFS='=' read -r key value; do
    [[ -z "${key}" || "${key}" == \#* ]] && continue
    [[ -z "${!key:-}" ]] && export "${key}=${value}"
  done < "${REPO_ROOT}/.env"
fi

export LAB_CLUSTER_NAME="${LAB_CLUSTER_NAME:-idp-lab}"
export LAB_HTTP_PORT="${LAB_HTTP_PORT:-80}"
export LAB_HTTPS_PORT="${LAB_HTTPS_PORT:-443}"
export LAB_DOMAIN="${LAB_DOMAIN:-localtest.me}"
export LAB_GITOPS_REPO="${LAB_GITOPS_REPO:-https://github.com/pablomartinvelasco/idp-tfg.git}"
export LAB_GITOPS_REVISION="${LAB_GITOPS_REVISION:-main}"

# Herramientas locales al proyecto y kubeconfig aislado (no se modifica ~/.kube/config).
export TOOLS_DIR="${REPO_ROOT}/.tools/bin"
export PATH="${TOOLS_DIR}:${PATH}"
export KUBECONFIG="${REPO_ROOT}/.kube/${LAB_CLUSTER_NAME}.yaml"
export KUBE_CONTEXT="kind-${LAB_CLUSTER_NAME}"

# Variables de entrada de Terraform derivadas de la configuración anterior (las que un módulo
# no declara se ignoran).
export TF_VAR_cluster_name="${LAB_CLUSTER_NAME}"
export TF_VAR_node_image="${KIND_NODE_IMAGE}"
export TF_VAR_kubeconfig_path="${KUBECONFIG}"
export TF_VAR_http_port="${LAB_HTTP_PORT}"
export TF_VAR_https_port="${LAB_HTTPS_PORT}"
export TF_VAR_kube_context="${KUBE_CONTEXT}"
export TF_VAR_domain="${LAB_DOMAIN}"
export TF_VAR_gitops_repo_url="${LAB_GITOPS_REPO}"
export TF_VAR_gitops_revision="${LAB_GITOPS_REVISION}"
export TF_VAR_argocd_chart_version="${ARGOCD_CHART_VERSION}"
export TF_VAR_argocd_apps_chart_version="${ARGOCD_APPS_CHART_VERSION}"
export TF_IN_AUTOMATION=1

if [[ -t 1 ]]; then
  C_RESET=$'\e[0m' C_RED=$'\e[31m' C_GREEN=$'\e[32m' C_YELLOW=$'\e[33m' C_DIM=$'\e[2m'
else
  C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_DIM=""
fi

log()  { printf '%s==>%s %s\n' "${C_DIM}" "${C_RESET}" "$*"; }
ok()   { printf '  %sOK%s    %s\n' "${C_GREEN}" "${C_RESET}" "$*"; }
warn() { printf '  %sWARN%s  %s\n' "${C_YELLOW}" "${C_RESET}" "$*"; }
fail() { printf '  %sFAIL%s  %s\n' "${C_RED}" "${C_RESET}" "$*"; }
die()  { printf '%sERROR:%s %s\n' "${C_RED}" "${C_RESET}" "$*" >&2; exit 1; }

require() {
  local bin
  for bin in "$@"; do
    command -v "${bin}" >/dev/null 2>&1 || die "'${bin}' no encontrado. Ejecuta 'make tools' o revisa docs/instalacion.md."
  done
}

kc() { kubectl --context "${KUBE_CONTEXT}" "$@"; }
