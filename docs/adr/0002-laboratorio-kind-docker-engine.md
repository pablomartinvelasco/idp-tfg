# ADR-0002 — kind sobre Docker Engine en WSL2, Kubernetes 1.35

**Estado**: Aceptado · **Fecha**: 12/10/2026 · **Objetivos**: O2 · **Requisitos**: RF-07, RNF-01

## Contexto
El laboratorio corre en un portátil (Ryzen 5 5600H, 16 GB, Windows + WSL2 Ubuntu 22.04). En la
inspección inicial no había Docker ni ninguna CLI de Kubernetes, y WSL tenía asignados 7,4 GiB.
La PEC1 deja abierta la elección entre kind y k3d.

## Decisión
1. **kind** como distribución del laboratorio, con **un único nodo** control-plane.
2. Creación del clúster con **Terraform** mediante el provider `tehcyx/kind` (`~> 0.11.0`).
3. **Kubernetes 1.35.0** (`kindest/node` fijada por digest), la versión por defecto de kind
   v0.31.0, que es la librería que embebe el provider. kind CLI fijado también en v0.31.0.
4. **Docker Engine** instalado en WSL2 desde el repositorio oficial (no Docker Desktop), con
   systemd habilitado. Script: `scripts/host/install-docker-wsl.sh`.
5. CLIs descargadas en `.tools/bin` con checksum verificado (`make tools`), sin `sudo`.
6. `.wslconfig` con `memory=10GB` (decisión del autor).

## Alternativas
- **k3d**: algo más ligero (k3s) y trae Traefik/servicelb integrados, pero su provider de
  Terraform no está mantenido, y k3s se aleja de un Kubernetes upstream (kubeadm), que es lo que se
  encuentra en EKS u otras distribuciones gestionadas. Los componentes integrados de k3s además se
  solaparían con los gestionados por Argo CD.
- **kind con script `kind create cluster --config`**: funcional, pero el clúster quedaría fuera
  del modelo IaC del TFG. Se mantiene como plan B si el provider falla (riesgo R2).
- **Kubernetes 1.37** (último estable): no está soportado por la librería de kind que embebe el
  provider; 1.35 sigue dentro del periodo de soporte de la comunidad durante todo el TFG.
- **Docker Desktop**: más simple de instalar, pero añade una VM y consumo de memoria, y su licencia
  no es completamente libre.

## Consecuencias
- Reconstrucción completa con `make tools && make up`.
- El kubeconfig se escribe en `.kube/idp-lab.yaml` (permisos 600, fuera de Git) y no altera
  `~/.kube/config`.
- Pertenecer al grupo `docker` equivale a root en WSL: limitación aceptada y documentada.
