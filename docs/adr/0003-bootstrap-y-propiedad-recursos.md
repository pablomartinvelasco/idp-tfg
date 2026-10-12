# ADR-0003 — Bootstrap en dos etapas de Terraform y propiedad única de recursos

**Estado**: Aceptado · **Fecha**: 12/10/2026 · **Objetivos**: O2, O3

## Contexto
Terraform, Helm y Argo CD pueden gestionar los mismos objetos. Si dos herramientas reconcilian un
recurso, sus cambios se pisan. Además Argo CD necesita existir antes de poder desplegar nada,
mientras que el resto de la plataforma debería venir de Git.

## Decisión
- **Etapa 1 — `infra/terraform/cluster`**: solo el `kind_cluster`.
- **Etapa 2 — `infra/terraform/bootstrap`** (S5): provider Helm sobre el kubeconfig de la etapa 1;
  instala el chart `argo-cd` y el chart `argocd-apps`, que crea los AppProjects y la Application raíz.
- **Etapa 3 — Argo CD**: todo lo demás (ingress, monitorización, Backstage, namespaces de entorno,
  servicios) se declara en `gitops/` y lo reconcilia Argo CD.
- Argo CD **no se autogestiona**. Su configuración cambia vía `terraform apply` de la etapa 2.
- Estado de Terraform en *backend local* (fuera de Git). Es un laboratorio de un solo operador;
  un backend remoto no aportaría nada y añadiría credenciales.
- Los namespaces `apps-dev`/`apps-staging` se aplican con `kubectl apply -k` hasta que exista
  Argo CD; entonces pasan a una Application de plataforma, que adopta los objetos existentes.

## Alternativas
- *Un único root module*: los providers Kubernetes/Helm se configurarían con atributos que no se
  conocen hasta crear el clúster; Terraform lo desaconseja explícitamente.
- *Argo CD self-managed* (Argo CD gestionando su propio chart tras instalarlo con Terraform): doble
  propiedad del mismo release, salvo que Terraform lo ignore después del primer `apply`, lo que
  rompe la reproducibilidad del estado.
- *Instalar todo con Terraform*: contradice O3; los cambios de plataforma no pasarían por GitOps.

## Consecuencias
- Tabla de propiedad explícita en `docs/arquitectura.md` §3.
- Recrear Argo CD no afecta al resto: al arrancar, vuelve a reconciliar desde Git.
