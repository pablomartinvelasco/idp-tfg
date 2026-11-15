# ADR-0008 — Backstage como portal frente a un portal propio o una solución gestionada

**Estado**: Aceptado · **Fecha**: 15/11/2026 · **Objetivos**: O4, O5, O6 · **Requisitos**: RF-01, RF-02, RF-05, RF-06

## Contexto
La PEC1 fija Backstage como portal. Esta decisión recoge, a petición del tutor, la comparación
con las alternativas razonables y los motivos de mantenerlo, para que no quede implícita.

## Criterios
1. **Catálogo y metadatos como código** (RF-01): descriptores versionados junto al servicio.
2. **Autoservicio por plantillas** (RF-02): generar repositorio y PR desde una plantilla.
3. **Integración con Kubernetes, Argo CD y métricas** (RF-05, RF-06).
4. **Coste y dependencia**: licencia, datos fuera del laboratorio, funcionamiento sin conexión.
5. **Esfuerzo de construcción y mantenimiento** por una sola persona en 14 semanas.
6. **Valor académico**: aportación de ingeniería demostrable y reproducible (RNF-01).

## Comparación
| Criterio | Backstage (elegida) | Portal propio (web + API sobre Git y Kubernetes) | Solución gestionada (p. ej. Port) |
|---|---|---|---|
| Catálogo como código | Nativo (`catalog-info.yaml`, ingestión desde GitHub) | Hay que diseñar modelo, ingestión y UI | Modelo de datos configurable, sincronizado desde Git o API |
| Plantillas | Scaffolder y plantillas YAML con acciones de GitHub | Hay que construir formularios, ejecución y trazabilidad | Acciones de autoservicio integradas |
| Kubernetes / Argo CD | Plugin de Kubernetes oficial; Argo CD por enlaces o plugin comunitario | Llamadas directas a la API; mantenimiento propio | Integraciones gestionadas; requieren un agente o credenciales hacia el SaaS |
| Documentación | TechDocs desde `mkdocs.yml` del servicio | A construir | Enlaces a documentación externa |
| Coste y datos | Código abierto; todo dentro del laboratorio | Solo tiempo de desarrollo | Servicio externo: los datos del clúster salen del laboratorio y no funciona sin conexión; condiciones del plan no evaluadas |
| Esfuerzo | Alto de arranque (compilar imagen, ~1 GiB de RAM) pero acotado y documentado | Muy alto: reimplementar lo anterior | Bajo de arranque; poca ingeniería propia que demostrar |
| Riesgos | Compatibilidad de plugins y versiones, cambios de API (R5) | Cobertura funcional incompleta; sin comunidad | Dependencia de un tercero y de su plan; difícil de reproducir (RNF-01) |
| Valor para el TFG | Alto: piezas estándar con integración propia (ADR, GitOps, plantilla) | Alto en código, pero se aleja del alcance de la PEC1 | Bajo: el aporte sería de configuración, no de plataforma |

## Decisión
Se mantiene **Backstage**, desplegado desde una imagen propia por GitOps (ADR-0007). Es el único
de los tres que cubre el catálogo, las plantillas y la documentación con componentes
mantenidos, funciona íntegramente dentro del laboratorio y permite reproducirlo desde el
repositorio (RNF-01). El portal propio se descarta por alcance y esfuerzo; Port, por la
dependencia de un servicio externo y por reducir la aportación a configuración.

## Consecuencias
- Coste asumido: imagen de ~250 MB, ~0,6–1,0 GiB de RAM con PostgreSQL y actualizaciones de
  versión de Backstage a gestionar (riesgos R4 y R5).
- La integración con Argo CD queda como enlaces desde la ficha mientras no se valide un plugin
  compatible con el *backend system* actual.
- La comparación es cualitativa; no se ha instalado ni medido Port. Si la memoria necesita una
  comparación cuantitativa, hay que obtenerla en una prueba aparte.
