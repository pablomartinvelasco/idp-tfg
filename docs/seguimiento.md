# Seguimiento del proyecto

Documento vivo para retomar el trabajo entre sesiones. Registra el estado real (implementado /
verificado / pendiente), las decisiones y las incidencias. Las decisiones de arquitectura se
detallan en `docs/adr/`.

## Estado actual (15/11/2026, revisión `bff74c8` + rama `pec2-integracion-k8s`)

**PEC2 — S7 fusionada, portal bloqueado por credenciales.** `main` local se avanzó (fast-forward)
a `origin/main` (`bff74c8`, PR #3 de S7). Rama de trabajo: `pec2-integracion-k8s`.

| Bloque | Implementado | Verificado (15/11/2026) | Pendiente |
|---|---|---|---|
| Clúster, Argo CD, Traefik, namespaces (O2, O3) | Terraform (`kind_cluster.lab`, `helm_release.argocd`, `helm_release.argocd_apps`) + Argo CD | Nodo `Ready` (v1.35.0); 7 Applications `Synced`, 6 `Healthy` | — |
| Servicios de ejemplo (O3) | `svc-catalogo`, `svc-pedidos` en dev (1 réplica) y staging (2) | 4 Applications `Synced`/`Healthy`; 6 pods `Running`; PA-03/04/05/13 superadas (12/10) | — |
| Portal Backstage (O4, S7) | `portal/`, imagen `639714d`, `gitops/platform/backstage` | Inicialmente no operativo (falta `backstage-secrets`); tras `make secrets`: pods listos, `make verify` completo OK, login con GitHub y catálogo funcionando | — |
| Acceso a Kubernetes desde el portal (RF-05, S8) | `rbac.yaml` (ServiceAccount + ClusterRole de solo lectura), `kubernetes:` en `app-config.production.yaml`, ADR-0009, comprobaciones en `make check`/`make verify` | `make check` OK; `apply --dry-run=server` OK. **PA-07 no ejecutada** | Publicar rama, imagen por CI, fijar `newTag`, fusionar y validar desde el portal |
| Catálogo (RF-01) | `catalog/*.yaml` + `catalog-info.yaml` de cada servicio (anotaciones, enlaces, propietario, TechDocs) | Metadatos revisados en origen; **PA-06 superada** (15/11/2026) | Añadir enlace a la Application de Argo CD en los `catalog-info.yaml` de los repos de servicio (requiere push a esos repos) |
| Justificación de ingeniería | `docs/ingenieria.md`, ADR-0008, ADR-0009 | Documentación; sin medidas | Comparación cuantitativa con Port solo si se necesita |
| Metodología DX | `docs/metodologia-dx.md`, `scripts/dx-medir.sh`, `scripts/dx-analisis.sh` | Análisis probado con datos sintéticos desechados; **0 mediciones reales** | Ejecutar tras S9 y S10 |
| Capturas | `docs/capturas.md`, `docs/evidencias/` | 3 capturas de texto seguras | Catálogo, TechDocs y vista Kubernetes tras desbloquear el portal |

## Próximos pasos

1. **Autor** (credenciales, no se piden por chat): crear la OAuth App de GitHub y el token
   *fine-grained*, rellenar `.env` (`AUTH_GITHUB_CLIENT_ID`, `AUTH_GITHUB_CLIENT_SECRET`,
   `GITHUB_TOKEN`) y ejecutar `make secrets` (`docs/instalacion.md` §7).
2. **Autor** (autorización): publicar `pec2-integracion-k8s` para que la CI construya la imagen
   del portal con la configuración de Kubernetes; después, un commit que fije `newTag` en
   `gitops/platform/backstage/kustomization.yaml` y PR a `main`.
3. Con el portal sano: `make verify`; ejecutar PA-06 y PA-07 desde el navegador y registrar la
   evidencia (capturas con revisión y fecha).
4. Retomar S9 (plantilla Scaffolder), S10 (Prometheus/Grafana) y S11 (permisos); después, el
   experimento DX.

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
| 15/11/2026 | Acceso de solo lectura del portal a Kubernetes con ServiceAccount in-cluster y ClusterRole mínimo (los Roles por namespace no sirven con la consulta del plugin) | ADR-0009 |
| 15/11/2026 | Backstage se mantiene frente a portal propio y Port (comparación cualitativa) | ADR-0008 |
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
| 15/11/2026 | `backstage` `Degraded` y pods en `CreateContainerConfigError` desde hace 28 días | `Secret backstage-secrets` inexistente: `make secrets` no se ha ejecutado y falta `.env` (credenciales de GitHub) | Pendiente de las credenciales del autor; procedimiento en `docs/instalacion.md` §7 |
| 15/11/2026 | El test E2E del portal presuponía acceso de invitado (botón `Enter`) | Plantilla de Backstage; ADR-0007 elimina el proveedor invitado | Reescrito: sin sesión debe mostrar solo GitHub. Sin ejecutar (requiere el entorno de Node y el portal); el flujo con OAuth se prueba manualmente |
