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
| PA-03 | Despliegue GitOps de 2 servicios en dev y staging | Sí | O3 · RF-03, RF-04 | Bootstrap de Argo CD; revisar Applications | 4 Applications `Synced`/`Healthy` en `apps-dev` y `apps-staging` | No ejecutada |
| PA-04 | Propagación de un cambio desde Git | Sí | O3 · RF-03, RNF-02 | Cambiar réplicas/etiqueta en un overlay y hacer push | Argo CD aplica el cambio sin intervención | No ejecutada |
| PA-05 | Rollback por Git | Sí | O3 · RNF-02 | `git revert` del cambio de PA-04 | El entorno vuelve a la revisión anterior | No ejecutada |
| PA-06 | Catálogo con ≥ 2 servicios y metadatos completos | Sí | O4 · RF-01 | Abrir catálogo y fichas | Nombre, descripción, propietario, repo, entorno, docs, estado y enlaces visibles | No ejecutada |
| PA-07 | Estado operativo en la ficha del servicio | No | O4 · RF-05 | Abrir pestañas Kubernetes / despliegue | Pods y estado de sync reales del clúster | No ejecutada |
| PA-08 | Alta de servicio de extremo a extremo con plantilla | Sí | O5 · RF-02 | Ejecutar plantilla, fusionar PR | Repo creado, servicio en catálogo y desplegado en ambos entornos sin editar configuración central | No ejecutada |
| PA-09 | Cuatro indicadores de observabilidad desde el portal | Sí | O6 · RF-06 | Desde la ficha abrir el dashboard | Estado de pods, CPU, memoria y peticiones con datos reales | No ejecutada |
| PA-10 | Ausencia de credenciales en Git | Sí | O7 · RNF-04 | `make check` + revisión del historial | Ningún patrón de credencial; `.env` y kubeconfig no versionados | No ejecutada |
| PA-11 | Separación de perfiles verificada en backend | Sí | O7 | Llamada a la API del portal / Argo CD como desarrollador a una acción de admin | Respuesta 403/denegación del backend | No ejecutada |
| PA-12 | Reconstrucción desde entorno limpio | Sí | O2 · RNF-01, RF-08 | Clon nuevo + guía de instalación | Plataforma operativa siguiendo solo la documentación | No ejecutada |
| PA-13 | Corrección de deriva (self-heal) | No | O3 · RNF-02 | `kubectl scale` manual de un servicio | Argo CD restablece el estado de Git | No ejecutada |
| PA-14 | Flujo principal siguiendo la guía breve | No | RNF-05 | Usuario sigue la guía de uso | Completa alta y consulta sin usar CLIs internas | No ejecutada |

Totales: 14 pruebas, 11 críticas.

## Registro de ejecuciones

| Fecha | Prueba | Resultado | Evidencia | Incidencias / correcciones |
|---|---|---|---|---|
| 12/10/2026 | PA-01 | Superada | `make preflight` correcto (Docker 29.9.0, 9,7 GiB, 12 CPU); `make up`: `terraform apply` 1 recurso añadido, `kind_cluster.lab` creado en 50 s con `kindest/node:v1.35.0`; namespaces `apps-dev`/`apps-staging` con ResourceQuota y LimitRange aplicados | Puerto 80 ocupado por Apache del host; el autor lo desactivó (`systemctl disable --now apache2`) antes de crear el clúster |
| 12/10/2026 | PA-02 | Superada | `make verify` (exit 0): 13/13 comprobaciones OK — clúster y kubeconfig (600), `/readyz`, nodo Ready con `ingress-ready=true`, kube-system y CoreDNS listos, versión v1.35.0, namespaces con etiqueta de entorno, cuota y LimitRange, pod de humo con DNS interno | — |

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
