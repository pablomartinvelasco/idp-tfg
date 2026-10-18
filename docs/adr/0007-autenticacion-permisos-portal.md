# ADR-0007 — Autenticación del portal con GitHub y perfiles definidos en el catálogo

**Estado**: Aceptado · **Fecha**: 12/10/2026 · **Objetivos**: O4, O7 · **Pruebas**: PA-11

## Contexto
El portal debe identificar a cada usuario y separar dos perfiles, *desarrollador* y
*administrador de plataforma*, con la restricción aplicada en el backend y no solo ocultando
botones (PEC1, O7). La PEC1 excluye un SSO corporativo; el laboratorio ya depende de GitHub para el
código, las imágenes y GitOps.

## Decisión
- **Inicio de sesión**: solo GitHub OAuth (OAuth App del autor; callback
  `http://portal.localtest.me/api/auth/github/handler/frame`). Elegido por el autor. No se instala
  el proveedor invitado: no existe ninguna vía de acceso sin identidad, tampoco en desarrollo.
- **Resolución de identidad**: `usernameMatchingUserEntityName`. Solo se emite identidad de
  Backstage para cuentas de GitHub con un `User` del mismo nombre en `catalog/org.yaml`; cualquier
  otra cuenta queda fuera aunque complete el OAuth.
- **Perfiles**: grupos `platform-admins` y `developers` (tipo `role`) en el catálogo. Pertenecer a
  uno u otro se decide por PR al repositorio de plataforma (trazable, RNF-02).
- **Autorización** (S11): política propia del framework de permisos en el backend, sobre la
  identidad emitida:
  - `platform-admins`: todas las acciones.
  - `developers`: lectura del catálogo y TechDocs, uso de plantillas; sin registrar ni borrar
    entidades ni ubicaciones del catálogo.
  - En S7 la política es *allow-all* para usuarios identificados; la frontera ya es la identidad.
- **Credenciales**: `AUTH_GITHUB_CLIENT_ID/SECRET` y un token *fine-grained* de solo lectura de
  repositorios públicos viven en `.env` y llegan al clúster como Secret (`make secrets`).
- **PA-11**: una segunda cuenta de GitHub (perfil desarrollador) intentará una acción de
  administrador contra la API; se espera 403. La cuenta se dará de alta en S11.

## Alternativas
- *Keycloak en el clúster*: usuarios de prueba sin depender de GitHub, pero 400–600 MiB más y un
  componente más que configurar y mantener.
- *Proveedor invitado*: sin identidad real; impide verificar perfiles en el backend.
- *oauth2-proxy delante del portal*: autentica, pero Backstage no conocería al usuario y no podría
  aplicar permisos por grupo.

## Consecuencias
- El portal requiere conexión con GitHub para iniciar sesión.
- La OAuth App está ligada a `portal.localtest.me`: cambiar dominio o puerto exige actualizarla.
- Alta de un usuario = `User` en `catalog/org.yaml` con su cuenta de GitHub y sus grupos.
