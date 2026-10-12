# Punto de entrada del laboratorio. La lógica vive en scripts/; aquí solo se orquesta.
# `make help` lista los objetivos.

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
SCRIPTS := ./scripts

.PHONY: help tools preflight check up plan down status namespaces verify kubeconfig

help: ## Muestra esta ayuda
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

tools: ## Descarga las CLIs fijadas en versions.env a .tools/bin
	@$(SCRIPTS)/install-tools.sh

preflight: ## Comprueba requisitos del host (Docker, memoria, puertos)
	@$(SCRIPTS)/preflight.sh

check: ## Verificaciones estáticas: shellcheck, terraform validate, kustomize, secretos
	@$(SCRIPTS)/check.sh

plan: ## terraform plan del clúster
	@$(SCRIPTS)/cluster.sh plan

up: ## Crea el clúster kind y aplica los namespaces de entorno
	@$(SCRIPTS)/cluster.sh up
	@$(MAKE) --no-print-directory namespaces

namespaces: ## Aplica gitops/platform/namespaces (transitorio hasta que Argo CD lo gestione, S5)
	@source $(SCRIPTS)/lib.sh && kc apply -k gitops/platform/namespaces

verify: ## Verificación funcional del clúster (PA-01, PA-02)
	@$(SCRIPTS)/verify-cluster.sh

status: ## Estado del clúster
	@$(SCRIPTS)/cluster.sh status

kubeconfig: ## Imprime el export de KUBECONFIG para usar kubectl en la shell actual
	@source $(SCRIPTS)/lib.sh && echo "export KUBECONFIG=$$KUBECONFIG"

down: ## Destruye el clúster (operación destructiva)
	@read -r -p "Se destruirá el clúster del laboratorio. ¿Continuar? [y/N] " ans && [[ "$$ans" == [yY] ]]
	@$(SCRIPTS)/cluster.sh down
