# Lista de capturas seguras para la memoria

Nomenclatura: `AAAA-MM-DD_<revisión git corta>_<tema>.<ext>` en `docs/evidencias/`. Nunca capturar
`.env`, kubeconfig, `Secret`, tokens, estados `.tfstate` completos ni el cliente OAuth. Si una
vista muestra un usuario, usar solo el nombre público de GitHub.

| # | Captura | Comando / vista | Estado | Fichero |
|---|---|---|---|---|
| 1 | Nodos del clúster | `kubectl get nodes` | **Capturada** (texto) | `2026-11-15_bff74c8_nodos.txt` |
| 2 | Applications de Argo CD (4 de servicios) | `kubectl get applications -n argocd` | **Capturada** (texto): 4 de servicios `Synced/Healthy`; `backstage` `Degraded` | `2026-11-15_bff74c8_applications.txt` |
| 3 | Recursos de Terraform reducidos a identificadores | `terraform state list` (solo direcciones) | **Capturada** | `2026-11-15_bff74c8_terraform-state-ids.txt` |
| 4 | Endpoints de los servicios | `curl` a `/` de las 4 URLs | Pendiente (hacerlo con `make verify` en verde) | — |
| 5 | Catálogo con 2 servicios | Portal → Catálogo | **Capturada** | `2026-11-15_bff74c8_pa06_catalogo-lista.png`, `…_ficha-svc-catalogo.png`, `…_ficha-svc-pedidos.png` |
| 6 | TechDocs de ambos servicios | Portal → Docs | **Capturada** | `…_pa06_techdocs-svc-catalogo.png`, `…_techdocs-svc-pedidos.png` |
| 7 | Vista Kubernetes de un servicio | Ficha → pestaña Kubernetes | **Pendiente**: requiere portal y nueva imagen | — |
| 8 | Salida de `make verify` completa | `make verify` | Pendiente (con el portal sano) | — |
| 9 | Matriz de pruebas | `docs/pruebas.md` | Disponible (actualizada) | — |
