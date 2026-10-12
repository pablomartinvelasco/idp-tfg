#!/usr/bin/env bash
# Comprueba que el equipo cumple los requisitos del laboratorio antes de crearlo.
# Sale con código distinto de 0 si falla algún requisito obligatorio.

source "$(dirname "$0")/lib.sh"

errors=0
check_fail() { fail "$*"; errors=$((errors + 1)); }

log "Herramientas (versions.env)"
for bin in kind kubectl helm terraform; do
  if [[ -x "${TOOLS_DIR}/${bin}" ]]; then ok "${bin} en .tools/bin"; else check_fail "${bin} no instalado: ejecuta 'make tools'"; fi
done

log "Docker"
if ! command -v docker >/dev/null 2>&1; then
  check_fail "docker no encontrado: ver scripts/host/install-docker-wsl.sh"
elif ! docker info >/dev/null 2>&1; then
  check_fail "el daemon de Docker no responde (¿servicio parado o usuario fuera del grupo docker?)"
else
  ok "Docker $(docker version --format '{{.Server.Version}}') (cgroup $(docker info --format '{{.CgroupVersion}}'))"
fi

log "Recursos"
mem_gib=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
mem_kib=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if (( mem_kib >= 9 * 1024 * 1024 )); then ok "Memoria: ${mem_gib} GiB"
elif (( mem_kib >= 7 * 1024 * 1024 )); then warn "Memoria: ${mem_gib} GiB (suficiente por fases; recomendado ≥ 10 GiB para el stack completo)"
else check_fail "Memoria: ${mem_gib} GiB (< 7 GiB)"
fi
ok "CPU: $(nproc) núcleos"
disk_gib=$(df -BG --output=avail "${REPO_ROOT}" | tail -1 | tr -dc '0-9')
if (( disk_gib >= 20 )); then ok "Disco libre: ${disk_gib} GiB"; else check_fail "Disco libre: ${disk_gib} GiB (< 20 GiB)"; fi

# kind recomienda subir estos límites cuando hay muchos pods (Prometheus, Backstage, etc.).
# https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
watches=$(cat /proc/sys/fs/inotify/max_user_watches)
instances=$(cat /proc/sys/fs/inotify/max_user_instances)
if (( watches >= 524288 )); then ok "inotify max_user_watches=${watches}"; else warn "inotify max_user_watches=${watches} (recomendado 524288)"; fi
if (( instances >= 512 )); then ok "inotify max_user_instances=${instances}"; else warn "inotify max_user_instances=${instances} (recomendado 512; lo ajusta scripts/host/install-docker-wsl.sh)"; fi

log "Puertos del host"
if kind get clusters 2>/dev/null | grep -qx "${LAB_CLUSTER_NAME}"; then
  ok "clúster '${LAB_CLUSTER_NAME}' ya existe; se omite la comprobación de puertos"
else
  for port in "${LAB_HTTP_PORT}" "${LAB_HTTPS_PORT}"; do
    if ss -Hltn "sport = :${port}" | grep -q .; then check_fail "puerto ${port} ocupado (ajusta LAB_HTTP_PORT/LAB_HTTPS_PORT en .env)"
    else ok "puerto ${port} libre"; fi
  done
fi

if (( errors > 0 )); then
  printf '\n'; die "${errors} comprobación(es) obligatoria(s) fallida(s)."
fi
log "Preflight correcto."
