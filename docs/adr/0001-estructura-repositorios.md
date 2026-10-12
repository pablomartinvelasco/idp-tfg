# ADR-0001 — Monorepo de plataforma y repositorios por servicio

**Estado**: Aceptado · **Fecha**: 12/10/2026 · **Objetivos**: O1, O3, O5

## Contexto
La IDP necesita versionar infraestructura, configuración GitOps, el portal y la documentación, y
además debe crear servicios nuevos desde una plantilla. Argo CD recomienda separar el código de la
aplicación de su configuración de despliegue para que un cambio de manifiestos no dispare CI y para
poder auditar los despliegues por separado.

## Decisión
- **`idp-tfg`** (este repositorio): monorepo de plataforma con `infra/`, `gitops/`, `portal/`
  (Backstage), `scripts/` y `docs/`. Es el repositorio de configuración que lee Argo CD.
- **`svc-<nombre>`**: un repositorio por servicio con código, `Dockerfile`, workflow de CI,
  `catalog-info.yaml` y documentación TechDocs. Los dos servicios de ejemplo siguen la misma
  estructura que generará la plantilla.
- La configuración de despliegue de cada servicio vive en `idp-tfg/gitops/apps/<nombre>/`.

## Alternativas
- *Todo en un repositorio*: más simple, pero la plantilla tendría que escribir código de aplicación
  en el repo de plataforma y desaparece la separación de responsabilidades.
- *Manifiestos dentro de cada repo de servicio*: obliga a descubrir repos (SCM provider generator,
  con token en Argo CD) y elimina el punto de revisión del equipo de plataforma.

## Consecuencias
- El alta de un servicio toca dos repositorios (repo nuevo + PR al de plataforma); ambas acciones
  existen como *actions* estándar del Scaffolder de Backstage.
- Los repos deben estar en GitHub (gratuito, público) para que Argo CD y GHCR funcionen sin
  credenciales en el clúster.
