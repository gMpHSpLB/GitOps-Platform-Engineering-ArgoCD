SHELL := /bin/bash

.DEFAULT_GOAL := help

RED    := \033[1;31m
YELLOW := \033[1;33m
GREEN  :="\033[1;32m"
CYAN   := \033[1;36m
RESET  := \033[0m

.PHONY: help
help: ## Show top-level targets
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Top-level targets:"
	@echo "  setup-minikube           Start/ensure Minikube cluster"
	@echo "  "
	@echo "  helm-lab-all             Run full Helm lab scripts"
	@echo ""
	@echo "See Makefile_Setup and Makefile_Setup_ArgoCD_GitOps_Platform_Engineering for detailed targets."
	@echo ""

# Convenience wrapper to call setup Makefile targets
.PHONY: setup-minikube
setup-minikube: ## Ensure Minikube cluster is running with correct profile
	@echo -e "$(CYAN) Ensure Minikube cluster is running with correct profile $(RESET)"; \
	$(MAKE) -f Makefile_Setup ensure-minikube
	$(MAKE) -f Makefile_Setup enable-minikube-addons
	$(MAKE) -f Makefile_Setup check-clusterinfo
	$(MAKE) -f Makefile_Setup kubectl-get-nodes

.PHONY: setup-argocd
setup-argocd: ## Ensure Minikube
	@printf '$(CYAN) %s $(RESET) \n' \
		' What will we do to setup ArgoCD: ' \
		' 		- Step 1. Setup Minikube ' \
		' 		- Step 2. Install ArgoCD on minikube ' \
		' 		- Step 3. ArgoCD Initial Setup (CLI install, Server Access, CLI login, Update Password ) '; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to continue..."; \
	read -r _

	@printf '$(CYAN) %s $(RESET) \n' "Step 1. Setup Minikube"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 1...";  \
	read -r _; \
	$(MAKE) setup-minikube; \
	echo " --------------------------------------------------------------------------------"

	@printf '$(CYAN) %s $(RESET) \n' "Step 2. Install ArgoCD on minikube"; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 2..."; \
	read -r _; \
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Platform_Engineering install_argocd_on_minikube; \
	echo " --------------------------------------------------------------------------------"

	@printf '$(CYAN) %s $(RESET) \n' \
		' Step 3. ArgoCD Initial Setup: ' \
		' 		- Access Argocd server UI ' \
		' 		- Get Initial Argocd Server Admin Password ' \
		' 		- Install Argocd CLI tool ' \
		' 		- Change UI Admin Password ' \
		'		- Login into Argocd Server UI ' \
		' 		- Optional: Delete Initial Adming Password '; \
	printf '$(CYAN) %s $(RESET) \n' "Press ENTER to run Step 3..."; \
	read -r _
	$(MAKE) -f Makefile_Setup_ArgoCD_GitOps_Platform_Engineering access-argocd-server-ui-and-do-initial-configuration


# Example: safe usage pattern
# Start from a clean shell.
# Run:
# bash
# make setup-minikube
# This ensures k8s-learning profile is up and configured.

# Then run:
# bash
# make setup-argocd
