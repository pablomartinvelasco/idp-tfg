# Plan y matriz de pruebas de aceptación (O8)

Criterio de la PEC1: **100 % de las pruebas críticas** y **≥ 90 % del total** superadas.
Una prueba solo se marca como superada tras ejecutarla y registrar su evidencia en el
[registro de ejecuciones](#registro-de-ejecuciones). Estados: *No ejecutada*, *Superada*,
*Fallida*, *Bloqueada*.

## Matriz

| ID | Prueba | Crítica | Objetivo / Req. | Procedimiento resumido | Resultado esperado | Estado |
|---|---|---|---|---|---|---|
| PA-01 | Creación del clúster desde código | Sí | O2 · RF-07, RNF-01 | `make tools && make up` en equipo con Docker | Clúster kind creado por Terraform sin pasos manuales | Superada |
| PA-02 | Verificación funcional del clúster y entornos | Sí | O2, O3 · RF-04 | `make verify` | Todas las comprobaciones OK (nodo, sistema, namespaces, cuotas, pod de humo) | Superada |
| PA-03 | Despliegue GitOps de 2 servicios en dev y staging | Sí | O3 · RF-03, RF-04 | Bootstrap de Argo CD; revisar Applications | 4 Applications `Synced`/`Healthy` en `apps-dev` y `apps-staging` | Superada |
| PA-04 | Propagación de un cambio desde Git | Sí | O3 · RF-03, RNF-02 | Cambiar réplicas/etiqueta en un overlay y hacer push | Argo CD aplica el cambio sin intervención | Superada |
| PA-05 | Rollback por Git | Sí | O3 · RNF-02 | `git revert` del cambio de PA-04 | El entorno vuelve a la revisión anterior | Superada |
| PA-06 | Catálogo con ≥ 2 servicios y metadatos completos | Sí | O4 · RF-01 | Abrir catálogo y fichas | Nombre, descripción, propietario, repo, entorno, docs, estado y enlaces visibles | No ejecutada |
| PA-07 | Estado operativo en la ficha del servicio | No | O4 · RF-05 | Abrir pestañas Kubernetes / despliegue | Pods y estado de sync reales del clúster | No ejecutada |
| PA-08 | Alta de servicio de extremo a extremo con plantilla | Sí | O5 · RF-02 | Ejecutar plantilla, fusionar PR | Repo creado, servicio en catálogo y desplegado en ambos entornos sin editar configuración central | No ejecutada |
| PA-09 | Cuatro indicadores de observabilidad desde el portal | Sí | O6 · RF-06 | Desde la ficha abrir el dashboard | Estado de pods, CPU, memoria y peticiones con datos reales | No ejecutada |
| PA-10 | Ausencia de credenciales en Git | Sí | O7 · RNF-04 | `make check` + revisión del historial | Ningún patrón de credencial; `.env` y kubeconfig no versionados | No ejecutada |
| PA-11 | Separación de perfiles verificada en backend | Sí | O7 | Llamada a la API del portal / Argo CD como desarrollador a una acción de admin | Respuesta 403/denegación del backend | No ejecutada |
| PA-12 | Reconstrucción desde entorno limpio | Sí | O2 · RNF-01, RF-08 | Clon nuevo + guía de instalación | Plataforma operativa siguiendo solo la documentación | No ejecutada |
| PA-13 | Corrección de deriva (self-heal) | No | O3 · RNF-02 | `kubectl scale` manual de un servicio | Argo CD restablece el estado de Git | Superada |
| PA-14 | Flujo principal siguiendo la guía breve | No | RNF-05 | Usuario sigue la guía de uso | Completa alta y consulta sin usar CLIs internas | No ejecutada |

Totales: 14 pruebas, 11 críticas.

## Registro de ejecuciones

| Fecha | Prueba | Resultado | Evidencia | Incidencias / correcciones |
|---|---|---|---|---|
| 12/10/2026 | PA-01 | Superada | `make preflight` correcto (Docker 29.9.0, 9,7 GiB, 12 CPU); `make up`: `terraform apply` 1 recurso añadido, `kind_cluster.lab` creado en 50 s con `kindest/node:v1.35.0`; namespaces `apps-dev`/`apps-staging` con ResourceQuota y LimitRange aplicados | Puerto 80 ocupado por Apache del host; el autor lo desactivó (`systemctl disable --now apache2`) antes de crear el clúster |
| 12/10/2026 | PA-02 | Superada | `make verify` (exit 0): 13/13 comprobaciones OK — clúster y kubeconfig (600), `/readyz`, nodo Ready con `ingress-ready=true`, kube-system y CoreDNS listos, versión v1.35.0, namespaces con etiqueta de entorno, cuota y LimitRange, pod de humo con DNS interno | — |
| 12/10/2026 | PA-03 | Superada | `make verify` (exit 0) tres veces seguidas: plataforma 37/37 OK. `svc-catalogo-dev`, `svc-catalogo-staging`, `svc-pedidos-dev` y `svc-pedidos-staging` `Synced`/`Healthy`; cada URL `http://<svc>.<entorno>.localtest.me/` informa su entorno y el SHA desplegado (`70363c4`, `38196b8`) y `/metrics` publica `app_build_info` | Ejecutada con la Application raíz y el ApplicationSet en la rama desechable `s6-prueba-argocd` (contenido del PR de S6 con la revisión de GitOps apuntando a esa rama); repetir `make verify` tras fusionar |
| 12/10/2026 | PA-04 | Superada | Commit `1ac4d87` (réplicas de `svc-pedidos` en dev 1 → 2) subido a las 18:32:12 UTC; sin refresco manual, `svc-pedidos-dev` queda `Synced`/`Healthy` en `1ac4d87` con 2/2 réplicas listas 304 s después | Misma rama desechable. El tiempo lo marca el sondeo de Git de Argo CD (120 s + hasta 60 s de *jitter*), sin webhook |
| 12/10/2026 | PA-05 | Superada | `git revert` → commit `5161f99` subido a las 18:37:32 UTC; sin intervención, `svc-pedidos-dev` vuelve a 1/1 réplica en `5161f99` tras 184 s | Misma rama desechable |
| 12/10/2026 | PA-13 | Superada | `kubectl scale deployment/svc-catalogo -n apps-dev --replicas=3` → Argo CD (`selfHeal`) lo devuelve a 1 réplica en 2 s; la Application sigue `Synced`/`Healthy` | — |

## Verificaciones técnicas

Comprobaciones de cada fase que no sustituyen a ninguna prueba de aceptación de la matriz (no
computan en el criterio de la PEC1), pero dejan evidencia del funcionamiento de cada pieza.

| Fecha | Verificación | Resultado | Evidencia |
|---|---|---|---|
| 12/10/2026 | S4 · Bootstrap de Argo CD (`make bootstrap`, revisión de la rama de trabajo) | Correcta | `terraform apply`: 2 recursos (`helm_release.argocd` en 31 s, `helm_release.argocd_apps` en 1 s); Argo CD v3.5.5; Applications `root`, `env-namespaces` y `traefik` en `Synced`/`Healthy` |
| 12/10/2026 | S4 · Idempotencia del bootstrap | Correcta | Segundo `make bootstrap`: `No changes`, 0 añadidos/cambiados/destruidos |
| 12/10/2026 | S4 · Verificación funcional (`make verify`) | Correcta | Clúster 13/13 OK; plataforma 20/20 OK (Argo CD disponible, AppProjects, 3 Applications sincronizadas y sanas, namespaces adoptados por `env-namespaces`, Traefik en el nodo `ingress-ready`, Ingress publicado en 127.0.0.1, `http://argocd.localtest.me` sirve la interfaz) |
| 12/10/2026 | S4 · Autorreparación de un recurso de plataforma | Correcta | `kubectl delete resourcequota/env-quota -n apps-dev` → Argo CD la restaura en 2 s con los mismos límites |
| 12/10/2026 | S4 · API de Argo CD a través de Traefik | Correcta | Login de `admin` en `/api/v1/session` → token; `/api/v1/applications` lista las 3 Applications del proyecto `platform`; sin token → HTTP 401 |
| 12/10/2026 | S4 · Consumo de memoria | Medido | `docker stats` del nodo `idp-lab-control-plane`: 1,41 GiB (clúster + Argo CD + Traefik) |
| 12/10/2026 | S6 · Pruebas unitarias de los servicios | Correcta | `go vet` y `go test` (Go 1.27.2): `svc-catalogo` 6/6 y `svc-pedidos` 7/7 en local; en CI con `-race` |
| 12/10/2026 | S6 · Imagen y ejecución endurecida | Correcta | Imágenes de 19,6 MB; contenedor con `--read-only --cap-drop ALL --security-opt no-new-privileges`: API, 404, `POST` (201 + `Location`) y `/metrics` correctos; 3,5 MiB de RAM |
| 12/10/2026 | S6 · CI de los servicios | Correcta | GitHub Actions: `svc-catalogo` run 38290239967 y `svc-pedidos` run 38290284910, *test* (~1 min) e *image* (~45 s) en verde; imágenes `ghcr.io/pablomartinvelasco/<svc>:<sha>` |
| 12/10/2026 | S6 · Descarga anónima desde GHCR | Correcta | Token anónimo + `GET /v2/<svc>/manifests/<sha>` → HTTP 200 en ambas imágenes: el clúster no necesita credenciales |
| 12/10/2026 | S6 · Validación de overlays contra el API server | Correcta | `kubectl apply --dry-run=server -k` de los 4 overlays: creados sin avisos de Pod Security `restricted` |
| 12/10/2026 | S6 · Reglas de `make check` para servicios | Correcta | Prueba negativa: overlay temporal `prod` con `newTag: latest` → 2 FAIL ("entorno dev o staging", "imagen fijada por SHA") y `make check` sale con error |
| 12/10/2026 | S6 · Frontera del AppProject `services` | Correcta | Application de prueba en `services` con destino `traefik` → `InvalidSpecError: ... do not match any of the allowed destinations in project 'services'`; 0 recursos creados; eliminada |
| 12/10/2026 | S6 · Propagación de un cambio de manifiestos | Correcta | Commit `d785a09` (etiquetas en los pods): las 4 Applications en `d785a09` y `Healthy` tras 205 s, sin refresco manual |
| 12/10/2026 | S6 · Consumo de memoria | Medido | Nodo `idp-lab-control-plane` con 6 pods de servicios (1 + 2 por servicio): 1,56 GiB; cuota usada: dev 2 pods / 32 Mi req., staging 4 pods / 64 Mi req. |
