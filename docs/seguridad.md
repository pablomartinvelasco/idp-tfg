# Seguridad y limitaciones (O7)

Controles del prototipo y limitaciones que impiden considerarlo apto para producción.

## Controles implementados (S3)

| Control | Implementación | Verificación |
|---|---|---|
| Credenciales fuera del repositorio | `.gitignore` (`.env`, `.kube/`, `*.tfstate`, claves); `.env.example` sin valores | `make check` (falla si `.env` está versionado o hay patrones de tokens GitHub/AWS o claves privadas) |
| Kubeconfig aislado | `.kube/idp-lab.yaml` con permisos 600, fuera de Git y de `~/.kube/config` | `make verify` |
| Integridad de herramientas | Descarga con verificación SHA-256 y versiones fijadas | `scripts/install-tools.sh` |
| Superficie de red mínima | Puertos del ingress publicados solo en `127.0.0.1` | `infra/terraform/cluster/variables.tf` |
| Endurecimiento de pods | Pod Security Admission `baseline` (aviso `restricted`) en `apps-*` | `make verify` (pod de humo cumple `restricted`) |
| Límites de recursos | `ResourceQuota` y `LimitRange` por entorno | `make verify` |
| Trazabilidad | Toda la configuración en Git | `git log` |

## Controles previstos

| Control | Fase | Diseño |
|---|---|---|
| Perfiles admin / desarrollador en el portal | S11 | Grupos `platform-admins` y `developers` en el catálogo; *permission policy* en el backend de Backstage (no solo ocultar botones) |
| RBAC de Argo CD | S5/S11 | Admin local deshabilitado tras el bootstrap o restringido; rol de solo lectura para desarrolladores; AppProjects `platform` y `services` |
| Acceso de Backstage a Kubernetes | S8 | ServiceAccount con ClusterRole de solo lectura |
| Revisión de cambios GitOps | S9 | El alta de servicios llega como PR; protección de rama `main` |
| Secretos de componentes | S7 | Secretos de Kubernetes creados desde `.env` por script (nunca en Git); tokens de GitHub con permisos mínimos (*fine-grained*) |

## Limitaciones conocidas

- Pertenecer al grupo `docker` equivale a privilegios de root en el host WSL.
- Estado de Terraform local y sin cifrar (contiene certificados de cliente del clúster); se excluye de Git.
- Sin NetworkPolicies entre entornos en S3: `apps-dev` y `apps-staging` comparten nodo y red.
- Sin SSO corporativo ni gestión avanzada de secretos (fuera de alcance por la PEC1).
- Tráfico HTTP sin TLS dentro del laboratorio.
- La detección de secretos de `make check` es por patrones; no sustituye a una herramienta como gitleaks.
