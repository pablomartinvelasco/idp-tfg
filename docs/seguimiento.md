# Seguimiento del proyecto

Documento vivo para retomar el trabajo entre sesiones. Registra el estado real (implementado /
verificado / pendiente), las decisiones y las incidencias. Las decisiones de arquitectura se
detallan en `docs/adr/`.

## Estado actual

**Semana S3 (12/10–18/10/2026) — Arquitectura v1 y laboratorio inicial.**

| Bloque | Implementado | Verificado | Pendiente |
|---|---|---|---|
| Arquitectura y requisitos (O1) | `docs/arquitectura.md`, `docs/requisitos.md`, ADR 0001–0005 | Revisión de coherencia con la PEC1 | ADR de autenticación/permisos del portal (S7) |
| Herramientas | `make tools` con checksums | Instalación real de kind v0.31.0, kubectl v1.35.9, helm v4.3.0, terraform 1.16.5, shellcheck v0.11.0; segunda ejecución idempotente | — |
| Host (Docker) | `scripts/host/install-docker-wsl.sh`, `.wslconfig` 10 GB | Docker 29.9.0 (cgroup v2), 9,7 GiB en WSL, `make preflight` correcto | — |
| Clúster (O2) | `infra/terraform/cluster` (provider `tehcyx/kind` 0.11.0), `scripts/cluster.sh` | `make up` crea `idp-lab` (v1.35.0) en 50 s; `make verify` OK (PA-01, PA-02 superadas) | — |
| Namespaces de entorno (O3) | `gitops/platform/namespaces` | Aplicados con `make up`; cuota y LimitRange verificados | Migrar su gestión a Argo CD (S5) |
| Comprobaciones | `make check`, `make preflight` | `make check` OK; prueba negativa con un token falso detectada; `make preflight` detecta la falta de Docker | — |

## Próximos pasos

1. Subir el commit inicial a `origin/main` (https://github.com/pablomartinvelasco/idp-tfg, público).
2. S4–S5: etapa `infra/terraform/bootstrap` (Argo CD + `argocd-apps`), Traefik, migrar namespaces a Argo CD.
3. S6: dos servicios de ejemplo (`svc-*`) con `/metrics`, CI a GHCR y `gitops/apps` con overlays.

## Decisiones tomadas

| Fecha | Decisión | Referencia |
|---|---|---|
| 12/10/2026 | kind (1 nodo) creado con Terraform; Kubernetes 1.35.0 | ADR-0002 |
| 12/10/2026 | Docker Engine en WSL (no Desktop); WSL a 10 GB — elegido por el autor | ADR-0002 |
| 12/10/2026 | Bootstrap en dos root modules; Argo CD no autogestionado | ADR-0003 |
| 12/10/2026 | Monorepo de plataforma + repos por servicio; alta por PR | ADR-0001 |
| 12/10/2026 | App-of-apps + ApplicationSet (git directory) + Kustomize overlays | ADR-0004 |
| 12/10/2026 | Traefik + `*.localtest.me` | ADR-0005 |
| 12/10/2026 | Namespaces `apps-dev`/`apps-staging` con PSA baseline, cuota y LimitRange | arquitectura §6 |
| 12/10/2026 | Repositorio público en GitHub: `pablomartinvelasco/idp-tfg` | ADR-0001 |
| 12/10/2026 | Helm 4 (v4.3.0) como CLI: Helm 3 deja de recibir soporte antes del fin del TFG | versions.env |

## Versiones fijadas

Fuente única: `versions.env`. Provider de Terraform: `.terraform.lock.hcl` de cada módulo.
Pendiente de fijar en su fase: chart de Argo CD (S5), Traefik (S5), kube-prometheus-stack (S10),
Backstage (S7; última estable consultada el 12/10/2026: v1.55.3).

## Skills de diseño (para S7 en adelante)

Localizadas en la inspección inicial (12/10/2026):

| Skill | Ubicación | Disponibilidad |
|---|---|---|
| Emil Kowalski (`emil-design-eng`) | `~/.claude/skills/emil-design-eng/SKILL.md` | Instalada e invocable |
| Taste (`design-taste-frontend`) | `~/.agents/skills/design-taste-frontend/SKILL.md` | Presente, no registrada como skill de Claude Code; se leerá directamente. Su propio alcance declara no estar pensada para dashboards ni tablas: se aplicará a criterio estético general |
| Impeccable | `~/.claude/plugins/marketplaces/impeccable/` | Marketplace clonado pero plugin **no instalado**; SKILL.md legible. Para usarla como skill: `/plugin install` desde ese marketplace |

## Incidencias

| Fecha | Incidencia | Causa | Solución |
|---|---|---|---|
| 12/10/2026 | Equipo sin Docker ni CLIs de Kubernetes; `sudo` requiere contraseña | Entorno nuevo | CLIs en `.tools/bin` sin root; Docker mediante script que ejecuta el autor |
| 12/10/2026 | shellcheck fallaba al analizar `versions.env` (SC1073) | Un comentario que empezaba por "shellcheck" se interpretaba como directiva | Comentario reformulado |
| 12/10/2026 | `make preflight`: puerto 80 ocupado | Apache 2.4 (`apache2.service`) activo en WSL | El autor lo desactiva (`systemctl disable --now apache2`); se mantienen 80/443 para URLs sin puerto |
| 12/10/2026 | Kubernetes 1.37 no utilizable con Terraform | El provider `tehcyx/kind` 0.11.0 embebe kind 0.31 | Kubernetes 1.35.0 (ADR-0002) |
