#!/usr/bin/env bash
# Crea o actualiza los secretos de la plataforma desde .env (RNF-04: nunca en Git).
# - namespace backstage (Argo CD le añade después las etiquetas de Pod Security)
# - Secret backstage-secrets: credenciales de GitHub del portal + contraseña de PostgreSQL
#   (generada la primera vez y conservada en ejecuciones posteriores).
# Los valores se pasan a kubectl mediante un fichero temporal 0600, no como argumentos.

source "$(dirname "$0")/lib.sh"
require kubectl openssl

NS=backstage
SECRET=backstage-secrets

missing=()
for key in AUTH_GITHUB_CLIENT_ID AUTH_GITHUB_CLIENT_SECRET GITHUB_TOKEN; do
  [[ -n "${!key:-}" ]] || missing+=("${key}")
done
if (( ${#missing[@]} > 0 )); then
  die "faltan en .env: ${missing[*]} (OAuth App y token de GitHub; ver docs/instalacion.md §5)."
fi

kc get namespace "${NS}" >/dev/null 2>&1 || kc create namespace "${NS}" >/dev/null

pg_password="$(kc get secret "${SECRET}" -n "${NS}" -o jsonpath='{.data.POSTGRES_PASSWORD}' 2>/dev/null | base64 -d || true)"
[[ -n "${pg_password}" ]] || pg_password="$(openssl rand -hex 24)"

envfile="$(mktemp)"
chmod 600 "${envfile}"
trap 'rm -f "${envfile}"' EXIT
{
  printf 'POSTGRES_PASSWORD=%s\n' "${pg_password}"
  printf 'AUTH_GITHUB_CLIENT_ID=%s\n' "${AUTH_GITHUB_CLIENT_ID}"
  printf 'AUTH_GITHUB_CLIENT_SECRET=%s\n' "${AUTH_GITHUB_CLIENT_SECRET}"
  printf 'GITHUB_TOKEN=%s\n' "${GITHUB_TOKEN}"
} > "${envfile}"

result="$(kc create secret generic "${SECRET}" -n "${NS}" --from-env-file="${envfile}" \
  --dry-run=client -o yaml | kc apply -f -)"
ok "${result}"

# Las variables de entorno solo se leen al arrancar: si el Secret cambió, se reinicia el portal.
if [[ "${result}" == *configured* ]] && kc get deployment/backstage -n "${NS}" >/dev/null 2>&1; then
  kc rollout restart deployment/backstage -n "${NS}" >/dev/null
  ok "portal reiniciado para leer los secretos nuevos"
fi
