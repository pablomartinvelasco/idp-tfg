# ADR-0004 — App-of-apps, ApplicationSet y overlays por entorno

**Estado**: Aceptado · **Fecha**: 12/10/2026 · **Objetivos**: O3, O5 · **Requisitos**: RF-03, RF-04

## Contexto
Se necesitan al menos dos servicios en dos entornos, promoción y rollback por Git, y que un
servicio nuevo se despliegue sin tocar configuración central del clúster.

## Decisión
- **Componentes de plataforma**: patrón *app-of-apps*. Cada componente es un `Application` en
  `gitops/platform/apps/` que referencia un chart upstream con versión fijada y `values` en Git.
- **Servicios**: un `ApplicationSet` con *Git directory generator* sobre
  `gitops/apps/*/overlays/*`, que genera una Application por servicio y entorno
  (`<svc>-<entorno>`) con destino `apps-<entorno>`.
- **Entornos**: Kustomize `base` + `overlays/dev` y `overlays/staging`.
- **Promoción**: PR que cambia la etiqueta de imagen en el overlay de staging. Imágenes inmutables
  (etiqueta = SHA del commit), nunca `latest`.
- **Rollback**: `git revert`. No se usa el rollback de la UI de Argo CD, que desincroniza Git.
- **Sync**: automático con `prune` y `selfHeal` en ambos entornos.

## Alternativas
- *Helm chart propio por servicio*: más potente, pero Kustomize es suficiente y deja
  manifiestos legibles para la memoria y para la plantilla.
- *Argo CD Image Updater* para promoción automática: añade un componente y escritura en Git desde el
  clúster; fuera de alcance.
- *Un clúster por entorno*: excluido por la PEC1.

## Consecuencias
- El alta de un servicio = añadir `gitops/apps/<svc>/` (lo hace la plantilla mediante PR).
- La historia de despliegues de cada entorno es la historia de su overlay en Git (RNF-02).
