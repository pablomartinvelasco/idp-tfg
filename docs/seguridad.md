# Seguridad y limitaciones (O7)

Controles del prototipo y limitaciones que impiden considerarlo apto para producción.

## Controles implementados (S3–S4)

| Control | Implementación | Verificación |
|---|---|---|
| Credenciales fuera del repositorio | `.gitignore` (`.env`, `.kube/`, `*.tfstate`, claves); `.env.example` sin valores | `make check` (falla si `.env` está versionado o hay patrones de tokens GitHub/AWS o claves privadas) |
| Kubeconfig aislado | `.kube/idp-lab.yaml` con permisos 600, fuera de Git y de `~/.kube/config` | `make verify` |
| Integridad de herramientas | Descarga con verificación SHA-256 y versiones fijadas | `scripts/install-tools.sh` |
| Superficie de red mínima | Puertos del ingress publicados solo en `127.0.0.1` | `infra/terraform/cluster/variables.tf` |
| Endurecimiento de pods | Pod Security Admission `baseline` (aviso `restricted`) en `apps-*` | `make verify` (pod de humo cumple `restricted`) |
| Límites de recursos | `ResourceQuota` y `LimitRange` por entorno | `make verify` |
| Trazabilidad | Toda la configuración en Git | `git log` |
| Fuente de verdad en Git | Argo CD con `prune` y `selfHeal`: la deriva manual se revierte | Borrado manual de la `ResourceQuota` de `apps-dev`, restaurada en 2 s (`docs/pruebas.md`) |
| Frontera de permisos GitOps | AppProject `services`: solo `apps-dev`/`apps-staging`, sin recursos de clúster ni cambios de cuotas, LimitRange o NetworkPolicy | `make verify` |
| Repositorio sin credenciales | Argo CD lee el repositorio público por HTTPS anónimo; no hay secretos de repositorio en el clúster | `infra/terraform/bootstrap` |
| Superficie de Argo CD | Sin Dex, notificaciones ni terminal web (`exec.enabled: false`); NetworkPolicies del chart limitan el acceso a repo-server y Redis | `infra/terraform/bootstrap/values/argocd.yaml.tftpl` |
| API de Argo CD autenticada | Peticiones sin token rechazadas | HTTP 401 en `/api/v1/applications` (`docs/pruebas.md`) |
| Protección de entornos | Namespaces con `Prune=false,Delete=false`: un cambio en Git no borra un entorno | `gitops/platform/namespaces` |

## Controles previstos

| Control | Fase | Diseño |
|---|---|---|
| Perfiles admin / desarrollador en el portal | S11 | Grupos `platform-admins` y `developers` en el catálogo; *permission policy* en el backend de Backstage (no solo ocultar botones) |
| RBAC de Argo CD | S11 | Admin local deshabilitado o restringido; rol de solo lectura para desarrolladores (los AppProjects ya existen desde S4) |
| Acceso de Backstage a Kubernetes | S8 | ServiceAccount con ClusterRole de solo lectura |
| Revisión de cambios GitOps | S9 | El alta de servicios llega como PR; protección de rama `main` |
| Secretos de componentes | S7 | Secretos de Kubernetes creados desde `.env` por script (nunca en Git); tokens de GitHub con permisos mínimos (*fine-grained*) |

## Limitaciones conocidas

- Pertenecer al grupo `docker` equivale a privilegios de root en el host WSL.
- Estado de Terraform local y sin cifrar (contiene certificados de cliente del clúster); se excluye de Git.
- Sin NetworkPolicies entre entornos en S3: `apps-dev` y `apps-staging` comparten nodo y red.
- Sin SSO corporativo ni gestión avanzada de secretos (fuera de alcance por la PEC1).
- Tráfico HTTP sin TLS dentro del laboratorio (incluido el login de Argo CD).
- Contraseña inicial de `admin` de Argo CD en el Secret `argocd-initial-admin-secret`, legible por
  quien tenga el kubeconfig; único usuario hasta definir perfiles (S11).
- Sin NetworkPolicies en `traefik` ni entre la plataforma y los entornos.
- La detección de secretos de `make check` es por patrones; no sustituye a una herramienta como gitleaks.
