# Requisitos, casos de uso y trazabilidad

Fuente: PEC1 (11/10/2026), apartados 2 y 3. Los identificadores se mantienen en todo el proyecto.

## 1. Actores

| Actor | Descripción | Capacidades |
|---|---|---|
| Desarrollador | Usuario del portal | Consultar catálogo, usar plantillas, proponer cambios por PR, ver estado y métricas |
| Administrador de plataforma | Responsable de la configuración base | Todo lo anterior + crear/destruir el laboratorio, aprobar PR de GitOps, administrar Argo CD |
| Argo CD (sistema) | Agente de reconciliación | Lectura de Git y escritura en el clúster dentro de sus AppProjects |

## 2. Requisitos funcionales

| ID | Requisito (PEC1) | Objetivo | Implementación prevista |
|---|---|---|---|
| RF-01 | Catálogo de servicios con metadatos de identificación, propietario y repositorio | O4 | Backstage Software Catalog + `catalog-info.yaml` por servicio |
| RF-02 | Plantilla de autoservicio que inicie un servicio con estructura estándar | O5 | Backstage Software Template |
| RF-03 | Despliegues de ejemplo gestionados con GitOps y descritos en Git | O3 | Argo CD + `gitops/apps` |
| RF-04 | Diferenciar los entornos desarrollo y preproducción | O3 | Namespaces `apps-dev` / `apps-staging` + overlays |
| RF-05 | Consultar desde el portal el estado del servicio y acceder a sus recursos | O4 | Plugins Kubernetes y Argo CD en la ficha del servicio, enlaces |
| RF-06 | Acceso a métricas de estado y consumo | O6 | Prometheus + Grafana, enlazados desde Backstage |
| RF-07 | Infraestructura y componentes base versionados como código | O2 | Terraform + Helm + manifiestos en Git |
| RF-08 | Documentación para instalar el laboratorio y repetir el flujo | O2, O8 | `README.md`, `docs/instalacion.md`, guía de uso |

## 3. Requisitos no funcionales

| ID | Requisito (PEC1) | Cómo se garantiza / verifica |
|---|---|---|
| RNF-01 Reproducibilidad | Instalación repetible desde repositorio y documentación | Versiones fijadas (`versions.env`, lock de Terraform, digest de imagen), `make up`, prueba desde entorno limpio (S13) |
| RNF-02 Trazabilidad | Cambios relevantes registrados en Git | GitOps con PR; Terraform versionado; `git log` como evidencia |
| RNF-03 Portabilidad | Sin recursos ni datos exclusivos de una empresa | Solo herramientas open source y servicios gratuitos; datos sintéticos |
| RNF-04 Seguridad básica | Sin secretos en texto plano en Git | `.gitignore`, `.env.example`, `make check` (patrones de tokens), secretos de Kubernetes creados fuera de Git |
| RNF-05 Usabilidad | Flujo de alta y consulta siguiendo una guía breve | Portal como punto único; guía de uso de una página; pruebas de aceptación de usuario |

## 4. Casos de uso

### CU-01 — Consultar el catálogo y la ficha de un servicio
- **Actor**: Desarrollador. **Requisitos**: RF-01, RF-05. **Objetivos**: O4.
- **Flujo**: accede al portal → lista de servicios filtrable por propietario/entorno → abre la ficha
  → ve descripción, propietario, repositorio, entornos, documentación, estado y enlaces.
- **Postcondición**: la información procede del catálogo y de integraciones reales, no de datos duplicados.

### CU-02 — Crear un servicio mediante plantilla
- **Actor**: Desarrollador (inicia), Administrador (aprueba). **Requisitos**: RF-02, RF-03, RF-04. **Objetivo**: O5.
- **Flujo**: elige plantilla → introduce nombre, descripción, propietario → el sistema crea el
  repositorio del servicio y abre un PR con su configuración GitOps → el administrador fusiona →
  Argo CD despliega en dev y staging → el servicio aparece en el catálogo.
- **Excepciones**: nombre duplicado o inválido (validación en el formulario); PR rechazado.

### CU-03 — Promocionar un cambio a staging y revertirlo
- **Actor**: Desarrollador / Administrador. **Requisitos**: RF-03, RF-04, RNF-02. **Objetivo**: O3.
- **Flujo**: cambio de etiqueta de imagen en el overlay de staging por PR → Argo CD sincroniza →
  si falla, `git revert` → Argo CD vuelve al estado anterior.

### CU-04 — Consultar el estado operativo y las métricas de un servicio
- **Actor**: Desarrollador. **Requisitos**: RF-05, RF-06. **Objetivo**: O6.
- **Flujo**: desde la ficha del servicio consulta pods y estado de sincronización → abre el
  dashboard de Grafana filtrado por servicio y entorno → revisa pods, CPU, memoria y peticiones.

### CU-05 — Reconstruir el laboratorio desde cero
- **Actor**: Administrador. **Requisitos**: RF-07, RF-08, RNF-01. **Objetivo**: O2.
- **Flujo**: `make tools` → `make up` → `make bootstrap` → Argo CD reconcilia el resto → `make verify`.

## 5. Matriz de trazabilidad

| Objetivo | Requisitos | Casos de uso | Artefactos | Pruebas | Estado |
|---|---|---|---|---|---|
| O1 Requisitos y arquitectura | — | todos | `docs/requisitos.md`, `docs/arquitectura.md`, `docs/adr/` | revisión | **Hecho (v1)** |
| O2 Base reproducible | RF-07, RF-08, RNF-01 | CU-05 | `infra/terraform/cluster`, `scripts/`, `Makefile`, `versions.env` | PA-01, PA-02, PA-12 | En curso: clúster y bootstrap hechos (S3–S4) |
| O3 GitOps | RF-03, RF-04, RNF-02 | CU-03 | `gitops/` | PA-03, PA-04, PA-05 | Argo CD, app-of-apps y namespaces por GitOps (S4); servicios en S6 |
| O4 Portal y catálogo | RF-01, RF-05 | CU-01 | `portal/` | PA-06, PA-07 | S7–S8 |
| O5 Autoservicio | RF-02 | CU-02 | plantilla Backstage | PA-08 | S9 |
| O6 Observabilidad | RF-06 | CU-04 | `gitops/platform/apps/monitoring` | PA-09 | S10 |
| O7 Seguridad y trazabilidad | RNF-02, RNF-04 | CU-02 | `docs/seguridad.md`, RBAC, `make check` | PA-10, PA-11 | Controles base hechos; resto S11 |
| O8 Validación | todos | todos | `docs/pruebas.md` | todas | S12–S13 |
