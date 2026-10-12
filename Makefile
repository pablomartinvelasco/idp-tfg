# Punto de entrada del laboratorio. La lógica vive en scripts/; aquí solo se orquesta.
# `make help` lista los objetivos.

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
SCRIPTS := ./scripts

.PHONY: help tools preflight check up bootstrap plan down status verify argocd-password kubeconfig

help: ## Muestra esta ayuda
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

tools: ## Descarga las CLIs fijadas en versions.env a .tools/bin
	@$(SCRIPTS)/install-tools.sh

preflight: ## Comprueba requisitos del host (Docker, memoria, puertos)
	@$(SCRIPTS)/preflight.sh

check: ## Verificaciones estáticas: shellcheck, terraform validate, kustomize, secretos
	@$(SCRIPTS)/check.sh

plan: ## terraform plan de las dos etapas (clúster y bootstrap)
	@$(SCRIPTS)/cluster.sh plan
	@$(SCRIPTS)/bootstrap.sh plan

up: ## Crea el clúster e instala Argo CD, que despliega la plataforma desde Git
	@$(SCRIPTS)/cluster.sh up
	@$(SCRIPTS)/bootstrap.sh up

bootstrap: ## Instala o actualiza Argo CD y la Application raíz (etapa 2, ADR-0003)
	@$(SCRIPTS)/bootstrap.sh up

verify: ## Verificación funcional: clúster (PA-01, PA-02) y plataforma GitOps
	@$(SCRIPTS)/verify-cluster.sh
	@$(SCRIPTS)/verify-platform.sh

status: ## Estado del clúster
	@$(SCRIPTS)/cluster.sh status

argocd-password: ## Muestra la contraseña inicial del usuario admin de Argo CD
	@$(SCRIPTS)/bootstrap.sh password

kubeconfig: ## Imprime el export de KUBECONFIG para usar kubectl en la shell actual
	@source $(SCRIPTS)/lib.sh && echo "export KUBECONFIG=$$KUBECONFIG"

down: ## Destruye el clúster (operación destructiva)
	@read -r -p "Se destruirá el clúster del laboratorio. ¿Continuar? [y/N] " ans && [[ "$$ans" == [yY] ]]
	@$(SCRIPTS)/cluster.sh down
