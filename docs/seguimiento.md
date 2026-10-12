# Seguimiento del proyecto

Documento vivo para retomar el trabajo entre sesiones. Registra el estado real (implementado /
verificado / pendiente), las decisiones y las incidencias. Las decisiones de arquitectura se
detallan en `docs/adr/`.

## Estado actual

**Semana S3 (12/10–18/10/2026) — Arquitectura v1 y laboratorio inicial.** Adelantados: S4–S5
(bootstrap de Argo CD, Traefik y namespaces por GitOps; fusionado en `main`, PR #1) y S6 (servicios
de ejemplo; rama `worktree-s6-servicios-ejemplo`, pendiente de fusionar).

| Bloque | Implementado | Verificado | Pendiente |
|---|---|---|---|
| Arquitectura y requisitos (O1) | `docs/arquitectura.md`, `docs/requisitos.md`, ADR 0001–0006 | Revisión de coherencia con la PEC1 | ADR de autenticación/permisos del portal (S7) |
| Herramientas | `make tools` con checksums | Instalación real de kind v0.31.0, kubectl v1.35.9, helm v4.3.0, terraform 1.16.5, shellcheck v0.11.0; segunda ejecución idempotente | — |
| Host (Docker) | `scripts/host/install-docker-wsl.sh`, `.wslconfig` 10 GB | Docker 29.9.0 (cgroup v2), 9,7 GiB en WSL, `make preflight` correcto | — |
| Clúster (O2) | `infra/terraform/cluster` (provider `tehcyx/kind` 0.11.0), `scripts/cluster.sh` | `make up` crea `idp-lab` (v1.35.0) en 50 s; `make verify` OK (PA-01, PA-02 superadas) | — |
| Namespaces de entorno (O3) | `gitops/platform/namespaces`, Application `env-namespaces` | Adoptados por Argo CD sin recrearlos; autorreparación de la cuota en 2 s | — |
| Bootstrap Argo CD (O2, O3) | `infra/terraform/bootstrap` (provider `hashicorp/helm` 3.3.0): `argo-cd` 10.10.3 (v3.5.5), `argocd-apps` 2.0.6; AppProjects `platform`/`services`; Application `root` | `apply` + idempotencia; `make verify` 20/20; login API y 401 sin token | — |
| Ingress (ADR-0005) | Application `traefik` (chart 41.7.1, Traefik v3.7.14) | `http://argocd.localtest.me` sirve la interfaz | — |
| Servicios de ejemplo (O3, ADR-0006) | Repos [`svc-catalogo`](https://github.com/pablomartinvelasco/svc-catalogo) y [`svc-pedidos`](https://github.com/pablomartinvelasco/svc-pedidos) (Go 1.27, distroless, CI → GHCR por SHA, `catalog-info.yaml`, TechDocs); `gitops/apps/<svc>` (base + overlays dev 1 réplica / staging 2); ApplicationSet `services` | 4 Applications `Synced`/`Healthy`; `make verify` 37/37 (×3); PA-03, PA-04, PA-05 y PA-13 superadas; frontera del proyecto `services` comprobada | Tras fusionar: `make bootstrap` (la raíz apunta hoy a `s6-prueba-argocd`) y `make verify`. ServiceMonitor en S10; grupos `equipo-catalogo`/`equipo-pedidos` y sistema `tienda-demo` en el catálogo (S7) |
| Comprobaciones | `make check`, `make preflight`, `make verify` (`verify-cluster.sh` + `verify-platform.sh`) | `make check` OK (versión de Traefik = `versions.env`; overlays solo `dev`/`staging` e imagen por SHA de 40 hex; ambas con prueba negativa); prueba negativa con un token falso detectada; `make preflight` detecta la falta de Docker | — |

## Próximos pasos

1. **Autor**: revisar y fusionar el PR de S6 (`worktree-s6-servicios-ejemplo`); después
   `git pull && make bootstrap && make verify` en `main` y borrar las ramas
   `worktree-s6-servicios-ejemplo` y `s6-prueba-argocd`.
2. Ejecutar `make down && make up && make verify` desde `main` para registrar PA-01/PA-02 con el
   flujo completo (clúster + bootstrap + servicios) y acercar PA-12.
3. S7: portal Backstage en `portal/`, ADR de autenticación y permisos, y entidades `Group`
   (`equipo-catalogo`, `equipo-pedidos`) y `System` (`tienda-demo`) que referencian los servicios.

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
| 12/10/2026 | Servicios `svc-catalogo` y `svc-pedidos` en Go (también lenguaje de la plantilla) — elegidos por el autor | ADR-0006 |
| 12/10/2026 | Imágenes distroless por SHA de commit; acciones de CI fijadas por SHA; paquetes GHCR públicos por herencia | ADR-0006 |
| 12/10/2026 | dev con 1 réplica y staging con 2 (diferencia visible entre entornos) | arquitectura §6 |
| 12/10/2026 | Applications de servicios con finalizador (retirar el directorio borra sus recursos); namespaces protegidos | arquitectura §5 |
| 12/10/2026 | Métricas por anotaciones `prometheus.io/*` hasta instalar el Prometheus Operator (ServiceMonitor en S10) | arquitectura §9 |
| 12/10/2026 | Cambios de GitOps probados antes de fusionar en una rama desechable (`LAB_GITOPS_REVISION` + revisión del ApplicationSet) | `docs/pruebas.md` |
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
| 12/10/2026 | `verify-platform.sh` fallaba de forma intermitente en `/metrics` de staging | El cliente de Prometheus no publica un contador con etiquetas hasta su primer uso; con 2 réplicas, el pod que responde puede no haber recibido peticiones | La comprobación usa `app_build_info`, presente en todos los pods desde el arranque (estable en 3 ejecuciones) |
| 12/10/2026 | `bootstrap.sh` solo esperaba a 3 Applications | Listaba las Applications antes de que el ApplicationSet generase las de servicios | Espera previa a `ResourcesUpToDate` de cada ApplicationSet |
| 12/10/2026 | Los pods no tenían las etiquetas `part-of` ni de entorno | `labels` de Kustomize no llega a la plantilla del pod sin `includeTemplates` | `includeTemplates: true` (selectores sin cambios) |
| 12/10/2026 | Kubernetes 1.37 no utilizable con Terraform | El provider `tehcyx/kind` 0.11.0 embebe kind 0.31 | Kubernetes 1.35.0 (ADR-0002) |
