# ADR-0006 — Servicios de ejemplo en Go con imagen distroless y CI hacia GHCR

**Estado**: Aceptado · **Fecha**: 12/10/2026 · **Objetivos**: O3, O5, O6 · **Requisitos**: RF-03, RF-06, RNF-01

## Contexto
La PEC1 pide al menos dos servicios de ejemplo desplegados en dos entornos, con métricas, y una
plantilla que genere servicios nuevos con la misma estructura. Cuatro pods (2 servicios × 2
entornos, más réplicas en staging) conviven con Argo CD, Backstage y Prometheus en un equipo de
8–16 GB, y las imágenes deben poder descargarse sin credenciales en el clúster (ADR-0001).

## Decisión
- **Servicios**: `svc-catalogo` (catálogo de productos, solo lectura) y `svc-pedidos` (consulta y
  alta de pedidos), con datos sintéticos en memoria (RNF-03). Elegidos por el autor.
- **Lenguaje**: Go con la biblioteca estándar (`net/http`) y el cliente oficial de Prometheus. Será
  también el lenguaje de la plantilla de autoservicio (S9). Elegido por el autor.
- **Contrato común** de todo servicio de la plataforma: `GET /healthz`, `GET /readyz`,
  `GET /metrics` con `http_requests_total`, `http_request_duration_seconds` y `app_build_info`;
  configuración por `PORT` y `APP_ENV`; logs JSON a stdout; parada ordenada con SIGTERM.
- **Imagen**: compilación multietapa y binario estático sobre `distroless/static:nonroot`
  (≈ 20 MB, sin shell), imágenes base fijadas por digest; en el clúster cumple Pod Security
  `restricted` (no root, sin capacidades, sistema de ficheros de solo lectura).
- **CI** (GitHub Actions, en cada repo de servicio): `go vet` y `go test -race` en cada push y PR;
  en `main`, imagen `ghcr.io/<owner>/<svc>:<sha completo>`. Acciones fijadas por SHA de commit.
- **Publicación**: los paquetes de GHCR heredan la visibilidad pública del repositorio; el
  clúster no necesita `imagePullSecrets`.

## Alternativas
- *Python (FastAPI)* o *Node.js*: más familiares para parte del público, pero imágenes de 50–60 MB y
  40–50 MiB de RAM por pod, frente a ≈ 3,5 MiB medidos en Go.
- *Etiqueta `latest` o por rama*: no inmutable; impide promoción y rollback trazables (ADR-0004).
- *Registro dentro del clúster*: evita depender de GHCR, pero añade un componente y rompe el flujo
  CI → registro → GitOps que se quiere mostrar.

## Consecuencias
- El alta de un servicio requiere que su primer build en CI termine antes de que Argo CD pueda
  descargar la imagen; la plantilla (S9) deberá contemplar ese orden.
- Un contador de Prometheus con etiquetas no aparece en `/metrics` hasta su primer uso: la
  verificación usa `app_build_info`, presente desde el arranque en cada pod.
