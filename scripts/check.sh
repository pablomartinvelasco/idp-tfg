#!/usr/bin/env bash
# Verificaciones estáticas de la configuración versionada. No requieren clúster ni Docker.

source "$(dirname "$0")/lib.sh"
require shellcheck terraform kubectl

errors=0
run() { # run <descripción> <comando...>
  local desc="$1" out; shift
  if out="$("$@" 2>&1)"; then ok "${desc}"; else fail "${desc}"; printf '%s\n' "${out}" | sed 's/^/        /'; errors=$((errors + 1)); fi
}

log "Scripts de shell"
mapfile -t scripts < <(git -C "${REPO_ROOT}" ls-files --cached --others --exclude-standard '*.sh')
run "shellcheck (${#scripts[@]} ficheros)" shellcheck -x -P "${REPO_ROOT}/scripts" "${scripts[@]/#/${REPO_ROOT}/}"

log "Terraform"
for dir in "${REPO_ROOT}"/infra/terraform/*/; do
  name="infra/terraform/$(basename "${dir}")"
  run "${name}: fmt" terraform -chdir="${dir}" fmt -check -recursive
  run "${name}: init (sin backend)" terraform -chdir="${dir}" init -backend=false -input=false
  run "${name}: validate" terraform -chdir="${dir}" validate
done

log "Manifiestos GitOps"
while IFS= read -r kfile; do
  dir="$(dirname "${kfile}")"
  run "${dir#"${REPO_ROOT}"/}: kustomize build" kubectl kustomize "${dir}"
done < <(find "${REPO_ROOT}/gitops" -name kustomization.yaml)

log "Versiones (versions.env como fuente única)"
traefik_app="${REPO_ROOT}/gitops/platform/apps/traefik.yaml"
run "chart de Traefik en GitOps = TRAEFIK_CHART_VERSION (${TRAEFIK_CHART_VERSION})" \
  grep -qE "^    targetRevision: ${TRAEFIK_CHART_VERSION//./\\.}\$" "${traefik_app}"

log "Secretos (RNF-04)"
run ".env no versionado" bash -c "! git -C '${REPO_ROOT}' ls-files --error-unmatch .env"
run "sin patrones de credenciales en ficheros versionables" bash -c \
  "! git -C '${REPO_ROOT}' grep -nIE --untracked -e 'gh[pousr]_[A-Za-z0-9]{36}' -e 'github_pat_[A-Za-z0-9_]{60,}' -e 'AKIA[0-9A-Z]{16}' -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' -- ':!scripts/check.sh'"

if (( errors > 0 )); then
  printf '\n'; die "${errors} comprobación(es) fallida(s)."
fi
log "Comprobaciones estáticas correctas."
