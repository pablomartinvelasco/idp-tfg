# Metodología de evaluación de Developer Experience (DX)

**Estado**: diseño del experimento; **no hay mediciones**. La comparación se ejecutará cuando
existan la plantilla de autoservicio (S9, RF-02) y la observabilidad (S10, RF-06). Hasta
entonces ninguna mejora se declara. Trazabilidad: O5, O6, O8 · RF-02, RF-05, RF-06 · PA-14.

## 1. Pregunta y diseño
¿Reduce la IDP el esfuerzo de tres tareas frente al procedimiento manual equivalente? Diseño
intrasujeto: el mismo evaluador ejecuta cada escenario en dos modalidades (**manual** e **idp**),
5 repeticiones por modalidad (30 ejecuciones), alternando el orden (M, I, I, M, M, I, …) para
repartir el efecto de aprendizaje. Cada repetición parte de un estado inicial limpio.

## 2. Escenarios
| Escenario | Estado inicial | Estado final verificable | Procedimiento manual | Procedimiento IDP |
|---|---|---|---|---|
| **alta** de servicio | No existe el servicio `svc-dx-N` (N = repetición) | Repositorio con CI y `catalog-info.yaml`; entidad en el catálogo; 2 Applications `Synced/Healthy`; `GET /` en dev y staging responde con su entorno | Crear repo desde el esqueleto, copiar CI, escribir `catalog-info.yaml` y `gitops/apps/svc-dx-N` (base + 2 overlays), abrir PR, fusionar, registrar la entidad | Rellenar la plantilla del portal y fusionar el PR que genera (S9) |
| **estado** del servicio | `svc-pedidos` desplegado; se introduce un fallo conocido (p. ej. imagen inexistente en staging, retirado tras cada repetición) | El evaluador identifica entorno afectado, causa visible (pod/evento) y réplicas listas | `kubectl get/describe` en cada namespace + interfaz de Argo CD | Ficha del servicio en el portal (pestaña Kubernetes y enlaces) |
| **métricas** | Servicio con tráfico generado por un script fijo | El evaluador anota el valor de las cuatro métricas de PA-09 (pods, CPU, memoria, peticiones/s) del servicio y entorno pedidos | Abrir Grafana/Prometheus, localizar el dashboard y filtrar por `namespace` y `service` | Enlace desde la ficha del servicio al dashboard ya filtrado (S10) |

El estado final se comprueba con una lista de verificación escrita antes de empezar; una
repetición que no lo alcanza se registra como no verificada y se excluye del cómputo.

## 3. Variables y registro
Por repetición: **tiempo** (s, desde la primera acción hasta el estado final), **acciones
manuales** (clics, comandos, ediciones de fichero), **cambios de herramienta** (ventana o
aplicación distinta) y **errores/reintentos** (acción repetida o deshecha).

- Cronómetro y registro: `scripts/dx-medir.sh <escenario> <manual|idp> <n>` añade una fila a
  `docs/dx/registro.csv` (plantilla: `docs/dx/registro-plantilla.csv`; columnas `escenario,
  modalidad, repeticion, inicio_utc, fin_utc, segundos, acciones_manuales, cambios_herramienta,
  errores_reintentos, estado_final_verificado, notas`). El script mide el tiempo; los conteos los
  introduce el evaluador y, por fiabilidad, se contrastan con la grabación de pantalla.
- Datos brutos inalterados en `docs/dx/registro.csv`; sin datos personales ni credenciales.
- Se registran también versiones (revisión Git, portal, plantilla) y el equipo.

## 4. Análisis
`scripts/dx-analisis.sh` calcula, por escenario y modalidad, la **mediana** de cada variable
(solo repeticiones verificadas) y la diferencia porcentual
`(mediana_IDP − mediana_manual) / mediana_manual × 100`. Se usan medianas y se publican también el
mínimo y el máximo; con n = 5 no se hace inferencia estadística, solo descripción. El script se
probó con datos sintéticos desechados; esos valores no forman parte de ningún resultado.

## 5. Sesgos y limitaciones
- **Mismo evaluador**, que además construyó la plataforma: conoce los atajos (sesgo a favor de
  ambas modalidades, más del procedimiento IDP). Se declara y, si es posible, se añade una
  persona externa con 1–2 repeticiones cualitativas.
- **Curva de aprendizaje**: la repetición mejora el tiempo; se mitiga alternando el orden y
  descartando una repetición de calentamiento por modalidad.
- **Latencia de CI y de sincronización**: construcción de imagen (~1 min) y sondeo de Git de
  Argo CD (hasta ~3 min sin webhook; PA-04 registró 304 s) dominan el tiempo del alta. Se
  informa el tiempo total y el tiempo «de manos» (acciones del evaluador), por separado.
- **Equipo local y red**: kind en WSL2 con DNS público; la variabilidad se informa con el rango.
- **Escenarios amañados**: el fallo del escenario *estado* es sintético; no representa
  incidentes reales.
- **Validez externa**: un laboratorio, dos servicios y una persona; sin extrapolar a organizaciones.

## 6. Requisitos previos para ejecutarlo
Plantilla Scaffolder operativa (S9), Prometheus/Grafana con el dashboard enlazado (S10), portal
con login y pestaña Kubernetes (PA-06/PA-07). Hasta entonces esta metodología solo queda
revisada, no ejecutada.
