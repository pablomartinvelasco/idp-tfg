# Justificación de ingeniería y fuentes de verdad

Estado a 15/11/2026 (revisión `bff74c8` + rama de trabajo). Describe lo implementado y verificado;
lo previsto se marca como tal. Ver también [arquitectura](arquitectura.md) y los [ADR](adr/README.md).

## 1. Backstage frente a alternativas
Matriz de criterios y decisión en [ADR-0008](adr/0008-backstage-frente-a-alternativas.md):
portal propio y solución gestionada (Port) comparadas con Backstage. La comparación es
cualitativa; no se ha instalado ni medido ninguna alternativa.

## 2. Argo CD: requisitos de GitOps y qué está implementado
| Capacidad | Implementación real | Evidencia |
|---|---|---|
| Estado deseado en Git | `gitops/platform` y `gitops/apps` en `main` | 8 Applications `Synced` en `bff74c8` |
| Reconciliación continua | `automated` con `prune` y `selfHeal` | PA-13: `scale` manual revertido en 2 s |
| Detección de deriva | Estado `OutOfSync` y autorreparación | PA-13; autorreparación de la cuota (S4) |
| Promoción entre entornos | PR que cambia `newTag` (SHA) en el overlay de cada entorno | PA-04 (304 s hasta `Healthy`) |
| Rollback | `git revert` del commit | PA-05 (184 s) |
| Generación de Applications | ApplicationSet `services` (generador `git directories`) → 4 Applications | S6; ADR-0004 |
| Aislamiento | AppProject `platform` (cluster-scope) y `services` (solo `apps-dev`/`apps-staging`, sin recursos de clúster) | Prueba de frontera de S6 |
| Pendiente | Webhook (hoy sondeo de 2–3 min), notificaciones, promoción automática, ApplicationSet para entornos nuevos | — |

## 3. Terraform: recursos exactos del estado verificado
Estado local (`*.tfstate`, no versionado), identificadores obtenidos con `terraform state list`
(`docs/evidencias/2026-11-15_bff74c8_terraform-state-ids.txt`):

| Módulo | Recurso | Qué crea |
|---|---|---|
| `infra/terraform/cluster` | `kind_cluster.lab` | Clúster kind `idp-lab` (1 nodo, Kubernetes 1.35.0, puertos 80/443) |
| `infra/terraform/bootstrap` | `helm_release.argocd` | Argo CD (chart `argo-cd` 10.10.3) |
| `infra/terraform/bootstrap` | `helm_release.argocd_apps` | AppProjects `platform`/`services` y Application `root` |

**Terraform no gestiona** Traefik, namespaces de entorno, Backstage, PostgreSQL, servicios ni el
RBAC del portal: son de Argo CD (ADR-0003). Excepción documentada: el namespace `backstage` y el
Secret `backstage-secrets` los crea `scripts/secrets.sh` desde `.env` porque el Secret no puede
estar en Git (RNF-04); Argo CD solo añade las etiquetas de Pod Security al namespace.

## 4. Fuentes de verdad
| Información | Dónde está | Notas |
|---|---|---|
| Existencia del clúster y de Argo CD | Estado de Terraform (local) + `infra/terraform/*` | El estado no está en Git; su pérdida exige reimportar o recrear |
| Versiones de herramientas y charts | `versions.env`, `.terraform.lock.hcl` | Fuente única; `make check` comprueba coincidencias |
| Configuración de plataforma | `gitops/platform/**` en Git | Argo CD la reconcilia |
| Configuración de servicios y entornos | `gitops/apps/<svc>/{base,overlays}` | Réplicas, host e imagen por entorno |
| Código de servicios e imágenes | Repos `svc-*` + GHCR (`ghcr.io/…/<svc>:<sha>`) | El overlay referencia el SHA |
| Catálogo | `catalog/*.yaml` + `catalog-info.yaml` de cada servicio | Backstage los ingiere desde GitHub |
| Secretos | `.env` (local) → Secret `backstage-secrets` | Nunca en Git |
| **Estado real del clúster** | **API de Kubernetes (etcd)** | **Git almacena el estado *deseado*, no el real; la divergencia la detecta Argo CD** |

## 5. Roles: modelo previsto y grado de implementación
| Aspecto | Modelo previsto (ADR-0007) | Estado real a 15/11/2026 |
|---|---|---|
| Identidad | GitHub OAuth; solo cuentas con `User` en el catálogo | Configurado; **no validado** (falta el Secret) |
| Perfiles | Grupos `developers` y `platform-admins` | Definidos en `catalog/org.yaml`; un solo usuario (administrador) |
| Autorización | Política propia en el backend (S11) | **Allow-all** para usuarios identificados: **no existe separación efectiva por perfil** |
| Argo CD | Administración reservada a `platform-admins` | Solo la cuenta `admin` de Argo CD |
| Acceso a Kubernetes desde el portal | Solo lectura (ADR-0009) | Manifiestos preparados; sin validar |
PA-11 sigue **no ejecutada**.

## 6. Aportación propia frente a instalación de componentes
| Aportación propia (diseño y código del proyecto) | Componentes de terceros instalados y configurados |
|---|---|
| Scripts (`scripts/*.sh`: clúster, bootstrap, verificación, secretos, medición DX) y `make check` | kind, Terraform y sus providers, Helm |
| Convención GitOps: app-of-apps + ApplicationSet + overlays por SHA, propiedad única de recursos (ADR-0003/0004) | Argo CD, Traefik |
| Servicios de ejemplo en Go con contrato común de endpoints y métricas, CI e imagen distroless (ADR-0006) | Prometheus, Grafana (pendientes) |
| Imagen y configuración del portal, perfiles en el catálogo, RBAC de solo lectura, ADR-0007/0008/0009 | Backstage y sus plugins (catálogo, TechDocs, Kubernetes, Scaffolder) |
| Diseño del autoservicio y de la evaluación DX (plantilla pendiente, S9) | PostgreSQL, GHCR, GitHub Actions |
Además, **API Go**: los dos servicios son código propio; el portal no contiene código propio más
allá de módulos de interfaz (inicio de sesión, tema, página de inicio).
