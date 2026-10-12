#!/usr/bin/env bash
# Verificación funcional del laboratorio Kubernetes (pruebas PA-01/PA-02, docs/pruebas.md).
# Cada comprobación imprime OK/FAIL; el script falla si alguna no se cumple.

source "$(dirname "$0")/lib.sh"
require kubectl kind

errors=0
check() { # check <descripción> <comando...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "${desc}"; else fail "${desc}"; errors=$((errors + 1)); fi
}

log "Clúster '${LAB_CLUSTER_NAME}' (contexto ${KUBE_CONTEXT})"
check "el clúster kind existe" bash -c "kind get clusters | grep -qx '${LAB_CLUSTER_NAME}'"
check "kubeconfig aislado presente con permisos 600" bash -c "[[ \$(stat -c %a '${KUBECONFIG}') == 600 ]]"
check "API server responde a /readyz" kc get --raw /readyz
check "todos los nodos en estado Ready" kc wait --for=condition=Ready nodes --all --timeout=120s
check "nodo con etiqueta ingress-ready=true" bash -c "kubectl --context '${KUBE_CONTEXT}' get nodes -l ingress-ready=true -o name | grep -q ."
check "pods de kube-system listos" kc wait --for=condition=Ready pods --all -n kube-system --timeout=180s
check "CoreDNS disponible" kc rollout status deployment/coredns -n kube-system --timeout=120s

expected_version="$(sed -E 's/^kindest\/node:(v[0-9.]+)@.*/\1/' <<< "${KIND_NODE_IMAGE}")"
check "versión del nodo = ${expected_version}" bash -c \
  "kubectl --context '${KUBE_CONTEXT}' get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}' | grep -qx '${expected_version}'"

log "Namespaces de entorno"
for env in dev staging; do
  ns="apps-${env}"
  check "${ns} existe con idp.tfg/environment=${env}" bash -c \
    "kubectl --context '${KUBE_CONTEXT}' get ns '${ns}' -o jsonpath='{.metadata.labels.idp\.tfg/environment}' | grep -qx '${env}'"
  check "${ns} tiene ResourceQuota y LimitRange" bash -c \
    "kubectl --context '${KUBE_CONTEXT}' get resourcequota/env-quota limitrange/default-resources -n '${ns}'"
done

log "Prueba de humo: pod efímero en apps-dev con resolución DNS interna"
smoke="smoke-$(date +%s)"
if kc run "${smoke}" -n apps-dev --image=busybox:1.37 --restart=Never --quiet \
     --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":65534,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"smoke","image":"busybox:1.37","command":["nslookup","kubernetes.default.svc.cluster.local"],"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}' \
     >/dev/null 2>&1 \
   && kc wait --for=jsonpath='{.status.phase}'=Succeeded "pod/${smoke}" -n apps-dev --timeout=120s >/dev/null 2>&1; then
  ok "pod programado, imagen descargada y DNS del clúster resuelto"
else
  fail "prueba de humo (ver: kubectl logs -n apps-dev ${smoke})"
  errors=$((errors + 1))
fi
kc delete pod "${smoke}" -n apps-dev --ignore-not-found --wait=false >/dev/null 2>&1 || true

if (( errors > 0 )); then
  printf '\n'; die "${errors} verificación(es) fallida(s)."
fi
log "Laboratorio verificado."
