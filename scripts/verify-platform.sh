#!/usr/bin/env bash
# Verificación funcional de la plataforma GitOps: Argo CD, AppProjects, Applications de
# gitops/platform, namespaces de entorno gestionados por Argo CD, acceso por Traefik y
# servicios desplegados por el ApplicationSet (un bloque por overlay de gitops/apps; PA-03).
# Cada comprobación imprime OK/FAIL; el script falla si alguna no se cumple.

source "$(dirname "$0")/lib.sh"
require kubectl curl

errors=0
check() { # check <descripción> <comando...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "${desc}"; else fail "${desc}"; errors=$((errors + 1)); fi
}
jp() { # jp <recurso> <namespace> <jsonpath>: imprime el campo indicado
  kubectl --context "${KUBE_CONTEXT}" get "$1" -n "$2" -o "jsonpath=$3"
}
equals() { # equals <esperado> <comando...>: la salida del comando es exactamente <esperado>
  local expected="$1"; shift
  [[ "$("$@")" == "${expected}" ]]
}

log "Argo CD (namespace argocd)"
check "Deployments disponibles" kc wait --for=condition=Available deployment --all -n argocd --timeout=180s
check "application-controller listo" kc rollout status statefulset/argocd-application-controller -n argocd --timeout=180s
check "AppProject platform existe" kc get appproject/platform -n argocd
check "AppProject services limitado a apps-dev/apps-staging" \
  equals "apps-dev apps-staging" jp appproject/services argocd '{.spec.destinations[*].namespace}'
check "AppProject services sin recursos de ámbito de clúster" \
  equals "" jp appproject/services argocd '{.spec.clusterResourceWhitelist}'
check "Application raíz sincroniza ${LAB_GITOPS_REVISION}" \
  equals "${LAB_GITOPS_REVISION}" jp application/root argocd '{.spec.source.targetRevision}'

log "Applications de plataforma (gitops/platform/apps)"
for app in root env-namespaces traefik; do
  check "${app}: Synced" equals Synced jp "application/${app}" argocd '{.status.sync.status}'
  check "${app}: Healthy" equals Healthy jp "application/${app}" argocd '{.status.health.status}'
done

log "Namespaces de entorno gestionados por Argo CD"
for ns in apps-dev apps-staging; do
  check "${ns} adoptado por la Application env-namespaces" bash -c \
    "kubectl --context '${KUBE_CONTEXT}' get ns '${ns}' -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' | grep -q '^env-namespaces:'"
done

log "Ingress (Traefik)"
check "Traefik disponible" kc rollout status deployment/traefik -n traefik --timeout=180s
check "Traefik en el nodo ingress-ready" bash -c \
  "node=\$(kubectl --context '${KUBE_CONTEXT}' get pods -n traefik -l app.kubernetes.io/name=traefik -o jsonpath='{.items[0].spec.nodeName}'); kubectl --context '${KUBE_CONTEXT}' get node \"\${node}\" -o jsonpath='{.metadata.labels.ingress-ready}' | grep -qx true"
check "IngressClass traefik por defecto" \
  equals true jp ingressclass/traefik default '{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}'
check "Ingress de Argo CD publicado en 127.0.0.1" \
  equals 127.0.0.1 jp ingress/argocd-server argocd '{.status.loadBalancer.ingress[0].ip}'

host="argocd.${LAB_DOMAIN}"
# Se fuerza la resolución a 127.0.0.1 para no depender del DNS público en esta comprobación.
check "http://${host} responde con la interfaz de Argo CD" bash -c \
  "curl -fsS --max-time 10 --resolve '${host}:${LAB_HTTP_PORT}:127.0.0.1' 'http://${host}:${LAB_HTTP_PORT}/' | grep -q '<title>Argo CD</title>'"
# localtest.me publica también ::1, que `getent hosts` devuelve primero: se consulta solo IPv4.
if getent ahostsv4 "${host}" | grep -q '^127\.0\.0\.1'; then
  ok "${host} resuelve a 127.0.0.1"
else
  warn "${host} no resuelve a 127.0.0.1 (¿sin DNS público?): ver ADR-0005"
fi

log "Servicios (ApplicationSet services, gitops/apps)"
check "ApplicationSet services existe" kc get applicationset/services -n argocd
shopt -s nullglob
for overlay in "${REPO_ROOT}"/gitops/apps/*/overlays/*/; do
  env="$(basename "${overlay}")"
  svc="$(basename "$(dirname "$(dirname "${overlay}")")")"
  app="${svc}-${env}"
  tag="$(sed -nE 's/^ *newTag: *([^ ]+).*/\1/p' "${overlay}kustomization.yaml")"
  check "${app}: Synced" equals Synced jp "application/${app}" argocd '{.status.sync.status}'
  check "${app}: Healthy" equals Healthy jp "application/${app}" argocd '{.status.health.status}'
  url="http://${svc}.${env}.${LAB_DOMAIN}:${LAB_HTTP_PORT}"
  resolve="${svc}.${env}.${LAB_DOMAIN}:${LAB_HTTP_PORT}:127.0.0.1"
  check "${app}: ${url%:*}/ informa entorno ${env} y versión ${tag:0:7}" bash -c \
    "curl -fsS --max-time 10 --resolve '${resolve}' '${url}/' | grep -q '\"entorno\":\"${env}\",.*\"version\":\"${tag}\"'"
  check "${app}: /metrics expone http_requests_total" bash -c \
    "curl -fsS --max-time 10 --resolve '${resolve}' '${url}/metrics' | grep -q '^http_requests_total'"
done
shopt -u nullglob

if (( errors > 0 )); then
  printf '\n'; die "${errors} verificación(es) fallida(s)."
fi
log "Plataforma GitOps verificada."
