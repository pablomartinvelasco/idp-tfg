#!/usr/bin/env bash
# Cronometra una repetición del experimento de Developer Experience (docs/metodologia-dx.md) y
# añade una fila a docs/dx/registro.csv. No mide nada por sí mismo: el evaluador introduce los
# conteos al terminar. Uso: scripts/dx-medir.sh <escenario> <manual|idp> <repeticion>
#   escenario: alta | estado | metricas

source "$(dirname "$0")/lib.sh"

scenario="${1:-}"; mode="${2:-}"; rep="${3:-}"
[[ "${scenario}" =~ ^(alta|estado|metricas)$ ]] || die "escenario: alta | estado | metricas"
[[ "${mode}" =~ ^(manual|idp)$ ]] || die "modalidad: manual | idp"
[[ "${rep}" =~ ^[0-9]+$ ]] || die "repeticion: número entero"

out="${REPO_ROOT}/docs/dx/registro.csv"
[[ -f "${out}" ]] || cp "${REPO_ROOT}/docs/dx/registro-plantilla.csv" "${out}"

read -r -p "Pulsa Enter para INICIAR el cronómetro (${scenario}/${mode}/rep ${rep})... " _
start_ns="$(date +%s%N)"; start_iso="$(date -u +%FT%TZ)"
read -r -p "Pulsa Enter al alcanzar el estado final... " _
end_ns="$(date +%s%N)"; end_iso="$(date -u +%FT%TZ)"
seconds="$(awk -v a="${start_ns}" -v b="${end_ns}" 'BEGIN { printf "%.1f", (b - a) / 1e9 }')"

read -r -p "Acciones manuales (clics, comandos, ediciones): " actions
read -r -p "Cambios de herramienta (ventana/aplicación): " switches
read -r -p "Errores o reintentos: " errors
read -r -p "¿Estado final verificado según el criterio del escenario? (si/no): " verified
read -r -p "Notas (sin comas ni datos sensibles): " notes

[[ "${actions}${switches}${errors}" =~ ^[0-9]+$ ]] || die "los conteos deben ser números enteros"
printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' "${scenario}" "${mode}" "${rep}" "${start_iso}" \
  "${end_iso}" "${seconds}" "${actions}" "${switches}" "${errors}" "${verified}" "${notes//,/;}" >> "${out}"
ok "registrado en docs/dx/registro.csv (${seconds} s)"
