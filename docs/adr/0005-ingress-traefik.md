# ADR-0005 — Traefik como ingress y dominios `*.localtest.me`

**Estado**: Aceptado · **Fecha**: 12/10/2026 · **Objetivos**: O4, RNF-05

## Contexto
El portal, Argo CD, Grafana y los servicios deben ser accesibles desde el navegador con URLs
estables. El proyecto ingress-nginx fue retirado por la comunidad Kubernetes en 2026, por lo que no
es una opción razonable para un proyecto nuevo.

## Decisión
- **Traefik** (chart oficial, gestionado por Argo CD) como controlador de `Ingress`, ejecutado en el
  nodo `ingress-ready=true` con `hostPort` 80/443, que kind publica en `127.0.0.1` del host.
- Dominios `*.localtest.me`, que resuelven públicamente a `127.0.0.1`: sin editar `/etc/hosts`
  ni en WSL ni en Windows.
- HTTP en el laboratorio; TLS con certificado autofirmado queda como mejora opcional.

## Alternativas
- *Gateway API con Envoy Gateway*: el estándar a futuro, pero más piezas (CRDs, controlador,
  proxy) para el mismo resultado en un laboratorio. Traefik también soporta Gateway API si se
  quisiera migrar.
- *`kubectl port-forward`*: sin URLs estables ni enlaces fiables desde Backstage.

## Consecuencias
- Requiere los puertos 80/443 libres en el host (lo comprueba `make preflight`; configurables).
- `localtest.me` depende de DNS público; sin conexión, añadir entradas en el fichero hosts.
