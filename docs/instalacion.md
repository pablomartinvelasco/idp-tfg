# Guía de instalación del laboratorio

Entorno de referencia: Windows 11 + WSL2 (Ubuntu 22.04), 16 GB de RAM. Contribuye a RF-08 y RNF-01.
El estado de validación de cada paso se registra en `docs/seguimiento.md`.

## 0. Requisitos del equipo

- WSL2 con Ubuntu 22.04 o superior (o Linux nativo x86_64).
- 8 GB de RAM como mínimo para fases parciales; recomendado 16 GB con `memory=10GB` para WSL.
- 20 GB libres en disco. Puertos 80 y 443 libres (configurables en `.env`).
- `git`, `curl`, `make`, `tar`, `unzip`, `xz`.

## 1. Memoria de WSL (solo Windows)

`C:\Users\<usuario>\.wslconfig`:

```ini
[wsl2]
memory=10GB
swap=4GB
```

## 2. Docker Engine en WSL (una vez, requiere sudo)

```bash
sudo scripts/host/install-docker-wsl.sh
```

Activa systemd, instala Docker Engine desde el repositorio oficial, añade tu usuario al grupo
`docker` y ajusta límites de inotify. Después, en PowerShell: `wsl --shutdown`, y vuelve a abrir
Ubuntu. Comprueba con `docker run --rm hello-world`.

En Linux nativo basta con tener Docker Engine instalado y el usuario en el grupo `docker`.

## 3. Herramientas del proyecto

```bash
make tools        # kind, kubectl, helm, terraform, shellcheck → .tools/bin (versions.env)
cp .env.example .env   # opcional: ajustar nombre del clúster o puertos
make check        # verificaciones estáticas
make preflight    # requisitos del host
```

## 4. Clúster

```bash
make up           # terraform apply + namespaces de entorno
make verify       # verificación funcional (PA-01, PA-02)
eval "$(make -s kubeconfig)"   # usar kubectl en la shell actual
```

`make down` destruye el clúster (pide confirmación).

## Pasos siguientes

Argo CD (`make bootstrap`), portal y observabilidad se añadirán a esta guía en las fases S5–S10.
