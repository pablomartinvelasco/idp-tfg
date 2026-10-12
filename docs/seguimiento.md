# Seguimiento del proyecto

Documento vivo para retomar el trabajo entre sesiones. Registra el estado real (implementado /
verificado / pendiente), las decisiones y las incidencias. Las decisiones de arquitectura se
detallan en `docs/adr/`.

## Estado actual

**Semana S3 (12/10–18/10/2026) — Arquitectura v1 y laboratorio inicial.** Adelantado S4: bootstrap
de Argo CD y plataforma GitOps (rama `worktree-s4-bootstrap-argocd`, pendiente de fusionar en `main`).

| Bloque | Implementado | Verificado | Pendiente |
|---|---|---|---|
| Arquitectura y requisitos (O1) | `docs/arquitectura.md`, `docs/requisitos.md`, ADR 0001–0005 | Revisión de coherencia con la PEC1 | ADR de autenticación/permisos del portal (S7) |
| Herramientas | `make tools` con checksums | Instalación real de kind v0.31.0, kubectl v1.35.9, helm v4.3.0, terraform 1.16.5, shellcheck v0.11.0; segunda ejecución idempotente | — |
| Host (Docker) | `scripts/host/install-docker-wsl.sh`, `.wslconfig` 10 GB | Docker 29.9.0 (cgroup v2), 9,7 GiB en WSL, `make preflight` correcto | — |
| Clúster (O2) | `infra/terraform/cluster` (provider `tehcyx/kind` 0.11.0), `scripts/cluster.sh` | `make up` crea `idp-lab` (v1.35.0) en 50 s; `make verify` OK (PA-01, PA-02 superadas) | — |
| Namespaces de entorno (O3) | `gitops/platform/namespaces`, Application `env-namespaces` | Adoptados por Argo CD sin recrearlos; autorreparación de la cuota en 2 s | — |
| Bootstrap Argo CD (O2, O3) | `infra/terraform/bootstrap` (provider `hashicorp/helm` 3.3.0): `argo-cd` 10.10.3 (v3.5.5), `argocd-apps` 2.0.6; AppProjects `platform`/`services`; Application `root` | `apply` + idempotencia; `make verify` 20/20; login API y 401 sin token | Volver a ejecutar `make bootstrap` tras fusionar (la raíz apunta hoy a la rama de trabajo) |
| Ingress (ADR-0005) | Application `traefik` (chart 41.7.1, Traefik v3.7.14) | `http://argocd.localtest.me` sirve la interfaz | — |
| Comprobaciones | `make check`, `make preflight`, `make verify` (`verify-cluster.sh` + `verify-platform.sh`) | `make check` OK (incluye versión de Traefik = `versions.env`, con prueba negativa); prueba negativa con un token falso detectada; `make preflight` detecta la falta de Docker | — |

## Próximos pasos

1. **Autor**: revisar y fusionar la rama `worktree-s4-bootstrap-argocd` en `main`; después
   `make bootstrap` para que la Application raíz pase a leer `main` (y borrar la rama remota).
2. Ejecutar `make down && make up && make verify` desde `main` para registrar PA-01/PA-02 con el
   flujo completo (clúster + bootstrap) y acercar PA-12.
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
| 12/10/2026 | Bootstrap y Traefik adelantados a S4 (planificados en S5) | ADR-0003, ADR-0005 |
| 12/10/2026 | `make up` = clúster + bootstrap; se elimina `make namespaces` (un único gestor por recurso) | ADR-0003 |
| 12/10/2026 | Traefik solo con el proveedor estándar de `Ingress` (sin CRDs propias ni Gateway API): menos memoria y menos piezas | ADR-0005 |
| 12/10/2026 | Namespaces de entorno con `Prune=false,Delete=false`; Applications sin finalizador en cascada | arquitectura §4 |
| 12/10/2026 | Repositorio y revisión de GitOps configurables (`LAB_GITOPS_REPO`/`LAB_GITOPS_REVISION`) para probar ramas antes de fusionar | `.env.example` |
| 12/10/2026 | Helm 4 (v4.3.0) como CLI: Helm 3 deja de recibir soporte antes del fin del TFG | versions.env |

## Versiones fijadas

Fuente única: `versions.env`. Provider de Terraform: `.terraform.lock.hcl` de cada módulo.
Fijadas en S4 (consultadas el 12/10/2026): `argo-cd` 10.10.3, `argocd-apps` 2.0.6, `traefik` 41.7.1
(la versión de Traefik está también en `gitops/platform/apps/traefik.yaml`; `make check` exige que
coincidan). Pendiente de fijar en su fase: kube-prometheus-stack (S10),
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
| 12/10/2026 | Service de Traefik creado como `LoadBalancer` pese a los valores | En el chart 41.x el tipo va en `service.spec.type`, no en `service.type` (ignorado sin error) | Detectado con `helm template` antes de desplegar; valor corregido |
| 12/10/2026 | Los symlinks `.tools`/`.kube` de un worktree entraban en un commit | Los patrones `.tools/` y `.kube/` de `.gitignore` solo excluyen directorios | Patrones sin barra final; commit corregido antes de subirlo |
| 12/10/2026 | `verify-platform.sh` avisaba de que `argocd.localtest.me` no resolvía a 127.0.0.1 | `getent hosts` devuelve primero el registro AAAA (`::1`) | Comprobación con `getent ahostsv4` |
| 12/10/2026 | Kubernetes 1.37 no utilizable con Terraform | El provider `tehcyx/kind` 0.11.0 embebe kind 0.31 | Kubernetes 1.35.0 (ADR-0002) |
