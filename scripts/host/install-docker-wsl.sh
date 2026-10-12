#!/usr/bin/env bash
# Prepara el host WSL2 (Ubuntu) para el laboratorio. Requiere root: `sudo scripts/host/install-docker-wsl.sh`
#
#  1. Activa systemd en WSL (/etc/wsl.conf), necesario para gestionar el servicio de Docker.
#  2. Instala Docker Engine desde el repositorio oficial de Docker (no Docker Desktop). ADR-0002.
#  3. Añade al usuario que invoca sudo al grupo docker.
#  4. Ajusta límites de inotify recomendados por kind.
#
# Es idempotente. Tras ejecutarlo hay que reiniciar WSL desde Windows: `wsl --shutdown`.

set -euo pipefail

[[ ${EUID} -eq 0 ]] || { echo "Ejecuta con sudo: sudo $0" >&2; exit 1; }
TARGET_USER="${SUDO_USER:-}"
[[ -n "${TARGET_USER}" && "${TARGET_USER}" != root ]] || { echo "Ejecuta con sudo desde tu usuario, no como root directamente." >&2; exit 1; }

# shellcheck source=/dev/null
. /etc/os-release
[[ "${ID}" == ubuntu ]] || { echo "Script preparado para Ubuntu (detectado: ${ID})." >&2; exit 1; }

echo "==> systemd en /etc/wsl.conf"
if grep -qsE '^\s*systemd\s*=\s*true' /etc/wsl.conf; then
  echo "    ya activado"
elif grep -qs '^\[boot\]' /etc/wsl.conf; then
  sed -i '/^\[boot\]/a systemd=true' /etc/wsl.conf
else
  printf '\n[boot]\nsystemd=true\n' >> /etc/wsl.conf
fi

echo "==> Repositorio oficial de Docker"
apt-get update -qq
apt-get install -y -qq ca-certificates curl >/dev/null
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-${VERSION_CODENAME}}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "==> Docker Engine"
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin >/dev/null
docker --version

echo "==> Grupo docker para ${TARGET_USER}"
# Nota de seguridad: pertenecer al grupo docker equivale a privilegios de root en el host
# WSL. Aceptado para un laboratorio local de un único usuario (docs/seguridad.md).
usermod -aG docker "${TARGET_USER}"

echo "==> Límites de inotify (kind known issues)"
cat > /etc/sysctl.d/99-idp-lab.conf <<'EOF'
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
sysctl -q --system

cat <<'EOF'

Hecho. Pasos restantes:
  1. En PowerShell (Windows):  wsl --shutdown
  2. Abre de nuevo la terminal de Ubuntu y comprueba:
       systemctl is-active docker   # → active
       docker run --rm hello-world
  3. En el repositorio:  make preflight && make up
EOF
