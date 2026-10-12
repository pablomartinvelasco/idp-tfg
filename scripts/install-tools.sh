#!/usr/bin/env bash
# Descarga las CLIs del laboratorio en .tools/bin con las versiones de versions.env,
# verificando su SHA-256. No requiere privilegios ni modifica el sistema.
# Docker Engine queda fuera: ver scripts/host/install-docker-wsl.sh.

source "$(dirname "$0")/lib.sh"
require curl sha256sum tar unzip

ARCH="amd64"
[[ "$(uname -m)" == "x86_64" ]] || die "Solo se soporta linux/amd64 en el laboratorio (detectado: $(uname -m))."

mkdir -p "${TOOLS_DIR}"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }

verify() { # verify <fichero> <sha256>
  echo "$2  $1" | sha256sum --check --quiet - || die "Checksum incorrecto para $(basename "$1")"
}

installed_version_matches() { # <bin> <cadena esperada en la salida de versión>
  [[ -x "${TOOLS_DIR}/$1" ]] && "${TOOLS_DIR}/$1" "${@:3}" 2>/dev/null | grep -q -- "$2"
}

install_kind() {
  if installed_version_matches kind "${KIND_VERSION}" version; then ok "kind ${KIND_VERSION} (ya instalado)"; return; fi
  local base="https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}"
  fetch "${base}/kind-linux-${ARCH}" "${WORK}/kind"
  fetch "${base}/kind-linux-${ARCH}.sha256sum" "${WORK}/kind.sha256"
  verify "${WORK}/kind" "$(cut -d' ' -f1 "${WORK}/kind.sha256")"
  install -m 0755 "${WORK}/kind" "${TOOLS_DIR}/kind"
  ok "kind ${KIND_VERSION}"
}

install_kubectl() {
  if installed_version_matches kubectl "${KUBECTL_VERSION}" version --client; then ok "kubectl ${KUBECTL_VERSION} (ya instalado)"; return; fi
  local base="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}"
  fetch "${base}/kubectl" "${WORK}/kubectl"
  fetch "${base}/kubectl.sha256" "${WORK}/kubectl.sha256"
  verify "${WORK}/kubectl" "$(cat "${WORK}/kubectl.sha256")"
  install -m 0755 "${WORK}/kubectl" "${TOOLS_DIR}/kubectl"
  ok "kubectl ${KUBECTL_VERSION}"
}

install_helm() {
  if installed_version_matches helm "${HELM_VERSION}" version; then ok "helm ${HELM_VERSION} (ya instalado)"; return; fi
  local tgz="helm-${HELM_VERSION}-linux-${ARCH}.tar.gz"
  fetch "https://get.helm.sh/${tgz}" "${WORK}/${tgz}"
  fetch "https://get.helm.sh/${tgz}.sha256sum" "${WORK}/helm.sha256"
  verify "${WORK}/${tgz}" "$(cut -d' ' -f1 "${WORK}/helm.sha256")"
  tar -xzf "${WORK}/${tgz}" -C "${WORK}"
  install -m 0755 "${WORK}/linux-${ARCH}/helm" "${TOOLS_DIR}/helm"
  ok "helm ${HELM_VERSION}"
}

install_terraform() {
  if installed_version_matches terraform "v${TERRAFORM_VERSION}" version; then ok "terraform ${TERRAFORM_VERSION} (ya instalado)"; return; fi
  local base="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"
  local zip="terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
  fetch "${base}/${zip}" "${WORK}/${zip}"
  fetch "${base}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" "${WORK}/tf.sums"
  verify "${WORK}/${zip}" "$(grep " ${zip}\$" "${WORK}/tf.sums" | cut -d' ' -f1)"
  unzip -qo "${WORK}/${zip}" terraform -d "${WORK}"
  install -m 0755 "${WORK}/terraform" "${TOOLS_DIR}/terraform"
  ok "terraform ${TERRAFORM_VERSION}"
}

install_shellcheck() {
  if installed_version_matches shellcheck "${SHELLCHECK_VERSION#v}" --version; then ok "shellcheck ${SHELLCHECK_VERSION} (ya instalado)"; return; fi
  local txz="shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
  fetch "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/${txz}" "${WORK}/${txz}"
  verify "${WORK}/${txz}" "${SHELLCHECK_SHA256}"
  tar -xJf "${WORK}/${txz}" -C "${WORK}"
  install -m 0755 "${WORK}/shellcheck-${SHELLCHECK_VERSION}/shellcheck" "${TOOLS_DIR}/shellcheck"
  ok "shellcheck ${SHELLCHECK_VERSION}"
}

log "Instalando herramientas en ${TOOLS_DIR}"
install_kind
install_kubectl
install_helm
install_terraform
install_shellcheck
log "Listo. Los targets de make añaden .tools/bin al PATH automáticamente."
