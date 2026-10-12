# IDP TFG — Internal Developer Platform sobre Kubernetes, GitOps e IaC

Trabajo Final de Grado, Ingeniería Informática (UOC). Autor: Pablo Martín Velasco.

*Diseño e implementación de una Internal Developer Platform (IDP) basada en Kubernetes, GitOps e
infraestructura como código.*

La plataforma ofrece a los desarrolladores un portal (Backstage) para consultar el catálogo de
servicios, crear servicios nuevos desde una plantilla y ver su estado y métricas, mientras Argo CD
despliega desde Git sobre un clúster Kubernetes local creado con Terraform.

## Estado

S6 — Argo CD instalado con Terraform; Traefik, namespaces y los servicios de ejemplo
[`svc-catalogo`](https://github.com/pablomartinvelasco/svc-catalogo) y
[`svc-pedidos`](https://github.com/pablomartinvelasco/svc-pedidos) desplegados por GitOps en
`apps-dev` y `apps-staging`. Detalle en
[`docs/seguimiento.md`](docs/seguimiento.md).

## Inicio rápido

```bash
sudo scripts/host/install-docker-wsl.sh   # una vez; después: wsl --shutdown
make tools        # CLIs fijadas en versions.env → .tools/bin
make preflight    # requisitos del host
make up           # clúster kind + Argo CD (Terraform); Argo CD despliega gitops/platform
make verify       # verificación funcional (clúster y plataforma GitOps)
make argocd-password   # contraseña inicial de admin para http://argocd.localtest.me
curl http://svc-catalogo.dev.localtest.me/api/productos   # servicio de ejemplo en dev
```

`make help` lista todos los objetivos. Guía completa: [`docs/instalacion.md`](docs/instalacion.md).

## Estructura

```text
.
├── Makefile                 # punto de entrada; delega en scripts/
├── versions.env             # versiones fijadas de todas las herramientas
├── .env.example             # configuración local (copiar a .env, no versionado)
├── scripts/                 # automatización: herramientas, preflight, clúster, verificación
│   └── host/                # preparación del host WSL (requiere sudo)
├── infra/terraform/
│   ├── cluster/             # etapa 1: clúster kind
│   └── bootstrap/           # etapa 2: Argo CD, AppProjects y Application raíz
├── gitops/                  # estado deseado que reconcilia Argo CD
│   ├── platform/
│   │   ├── apps/            # app-of-apps: Traefik, namespaces, ApplicationSet de servicios
│   │   └── namespaces/      # entornos apps-dev y apps-staging
│   └── apps/<svc>/          # despliegue de cada servicio: base + overlays dev/staging
└── docs/                    # memoria técnica: arquitectura, requisitos, ADRs, pruebas
```

Directorio previsto en fases posteriores: `portal/` (S7). El código de cada servicio vive en su
propio repositorio `svc-<nombre>` (ADR-0001).

## Documentación

| Documento | Contenido |
|---|---|
| [Arquitectura](docs/arquitectura.md) | Componentes, propiedad de recursos, bootstrap, GitOps, entornos, riesgos |
| [Requisitos](docs/requisitos.md) | RF-01–RF-08, RNF-01–RNF-05, casos de uso, trazabilidad con O1–O8 |
| [ADRs](docs/adr/README.md) | Decisiones de arquitectura |
| [Instalación](docs/instalacion.md) | Reconstrucción del laboratorio desde cero |
| [Pruebas](docs/pruebas.md) | Plan y registro de pruebas de aceptación |
| [Seguridad](docs/seguridad.md) | Controles y limitaciones |
| [Seguimiento](docs/seguimiento.md) | Estado, decisiones e incidencias por sesión |
