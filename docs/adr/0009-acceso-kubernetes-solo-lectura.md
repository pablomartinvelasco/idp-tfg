# ADR-0009 — Acceso de solo lectura del portal a Kubernetes

**Estado**: Aceptado · **Fecha**: 15/11/2026 · **Objetivos**: O4, O7 · **Requisitos**: RF-05, RNF-04 · **Pruebas**: PA-07

## Contexto
La ficha de cada servicio debe mostrar pods y despliegues reales (RF-05). El backend de Backstage
corre dentro del propio clúster kind, que es el único que consulta. No se admite `cluster-admin`
ni un token en Git (RNF-04).

## Decisión
- **Clúster y autenticación**: un solo clúster `idp-lab` (`https://kubernetes.default.svc`) con
  `authProvider: serviceAccount` y **sin** `serviceAccountToken`: el plugin usa el token y la CA
  que el kubelet monta en el pod (comprobado en el código de `plugin-kubernetes-backend` incluido
  en la imagen). No hay token en Git ni en el Secret.
- **Identidad**: `ServiceAccount` `backstage` (la única con token montado en ese namespace).
- **Permisos**: `ClusterRole` `backstage-kubernetes-reader` con `get/list/watch` sobre `pods`,
  `services`, `deployments`, `replicasets` e `ingresses`; el plugin se limita a esos tipos con
  `kubernetes.objectTypes`. No incluye Secrets, ConfigMaps, logs, exec ni verbos de escritura.
- **Localización de recursos**: la etiqueta `backstage.io/kubernetes-id=<servicio>` que ya llevan
  los Deployment y los pods; la ficha de cada servicio muestra los dos entornos.

## Alternativas
- *Roles por namespace* (`apps-dev`, `apps-staging`): es la opción preferible por mínimo
  privilegio, pero el plugin consulta cada tipo en todo el clúster con el selector de etiqueta
  cuando la entidad no declara `backstage.io/kubernetes-namespace`, y un componente que vive en
  dos namespaces no puede declarar uno solo. Con Roles esa consulta devuelve 403. Si el plugin
  admite varios namespaces en una versión futura, se sustituye el ClusterRole.
- *Token estático en el Secret*: funciona, pero es una credencial de larga duración que habría
  que rotar y custodiar.
- *`localKubectlProxy`*: solo válido para desarrollo local.

## Consecuencias
- El portal puede *listar* metadatos de esos cinco tipos en cualquier namespace; el filtro por
  etiqueta limita lo que se muestra, no lo que RBAC permite. Es un riesgo acotado y asumido, a
  revisar si se añaden más clústeres o entornos.
- El plugin aún no filtra por identidad del usuario: cualquier usuario autenticado del portal ve
  los mismos recursos (la política de permisos, S11, lo acotará).
- Sin metrics-server, el uso de CPU y memoria no aparece en la ficha (`skipMetricsLookup`);
  las métricas llegarán por Prometheus/Grafana (S10).
