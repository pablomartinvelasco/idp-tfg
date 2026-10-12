# Notas para Claude Code

TFG (UOC): IDP sobre Kubernetes (kind), Terraform, Argo CD, Backstage, Prometheus/Grafana.

- **Antes de trabajar, lee `docs/seguimiento.md`** (estado real, próximos pasos, decisiones) y los ADRs
  relevantes en `docs/adr/`. Actualiza `docs/seguimiento.md` al cerrar cada iteración.
- Fuente de alcance: PEC1 (`Martín_Velasco_Pablo_TFG_PEC1.pdf`, Escritorio de OneDrive del autor).
  No ampliar alcance sin autorización.
- Documentación en español (académico-técnico); código, identificadores y comentarios técnicos pueden ir en inglés.
- Trazabilidad con O1–O8, RF-01–RF-08, RNF-01–RNF-05, PA-xx.
- Nunca marcar una prueba como superada sin ejecutarla y registrar evidencia en `docs/pruebas.md`.
- Versiones: fuente única `versions.env`. CLIs en `.tools/bin` (`make tools`); los scripts las añaden al PATH.
- kubectl: usar `source scripts/lib.sh && kc ...` o `eval "$(make -s kubeconfig)"`; el kubeconfig es `.kube/idp-lab.yaml`.
- Propiedad de recursos (ADR-0003): Terraform = clúster + Argo CD; Argo CD = todo lo demás. No gestionar un recurso con dos herramientas.
- Verificar con `make check` antes de dar por terminado un cambio.
