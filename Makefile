SHELL := /bin/bash

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

NAMESPACE ?= abcdesktop
RELEASE ?= abcdesktop

REMOTE_REPO_NAME ?= abcdesktopio
REMOTE_REPO_URL ?= https://abcdesktopio.github.io/helm/
CHART_NAME ?= abcdesktop

LOCAL_CHART ?= ./charts/abcdesktop

VALUES ?= -f ./tests/values.yaml
EXTRA_ARGS ?=

# --- MongoDB password rotation ---
MONGO_POD ?= mongodb-od-0
MONGO_SECRET_NAME ?= secret-mongodb
MONGO_PASSWORD_LENGTH ?= 24
MONGO_RESTART_TARGETS ?= deployment/pyos-od
MONGO_STATEFULSET ?= mongodb-od
MONGO_CONTAINER ?= mongodb
LIVENESS_TEST_TIMEOUT ?= 180

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

.PHONY: help
help:
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make repo-add              Add the helm repository"
	@echo "  make repo-update           Update the helm repository"
	@echo ""
	@echo "  make install-remote        Install from the remote repository"
	@echo "  make uninstall-remote      Uninstall"
	@echo ""
	@echo "  make install-local         Install from the local chart"
	@echo "  make uninstall-local       Uninstall"
	@echo ""
	@echo "  make check-images          Check that the chart images are available"
	@echo ""
	@echo "  make test-mongo-liveness   Check that the MongoDB livenessProbe properly restarts the pod"
	@echo ""	
	@echo "  make rotate-mongo-password Rotate MongoDB passwords (root + pyos)"
	@echo ""	
	@echo "Variables:"
	@echo "  NAMESPACE=abcdesktop"
	@echo "  RELEASE=abcdesktop"
	@echo "  VALUES=-f ./tests/values.yaml"
	@echo "  EXTRA_ARGS=..."
	@echo "  MONGO_POD=mongodb-od-0"
	@echo "  MONGO_SECRET_NAME=secret-mongodb"
	@echo "  MONGO_PASSWORD_LENGTH=24"	
	@echo "  MONGO_RESTART_TARGETS=deployment/pyos-od"
	@echo "  MONGO_STATEFULSET=mongodb-od"
	@echo "  MONGO_CONTAINER=mongodb"
	@echo "  LIVENESS_TEST_TIMEOUT=180"
	@echo ""

# -----------------------------------------------------------------------------
# Repository
# -----------------------------------------------------------------------------

.PHONY: repo-add
repo-add:
	helm repo add $(REMOTE_REPO_NAME) $(REMOTE_REPO_URL)

.PHONY: repo-update
repo-update:
	helm repo update

# -----------------------------------------------------------------------------
# Install from remote repository
# -----------------------------------------------------------------------------

.PHONY: install-remote
install-remote: repo-add repo-update
	helm upgrade --install \
		$(RELEASE) \
		$(REMOTE_REPO_NAME)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		$(VALUES) \
		$(EXTRA_ARGS)

.PHONY: uninstall-remote
uninstall-remote:
	helm uninstall $(RELEASE) -n $(NAMESPACE)

# -----------------------------------------------------------------------------
# Install from local chart
# -----------------------------------------------------------------------------

.PHONY: install-local
install-local:
	helm upgrade --install \
		$(RELEASE) \
		$(LOCAL_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		$(VALUES) \
		$(EXTRA_ARGS)

.PHONY: uninstall-local
uninstall-local:
	helm uninstall $(RELEASE) -n $(NAMESPACE)

.PHONY: lint
lint:
	helm lint $(LOCAL_CHART)

.PHONY: template
template:
	@echo "WARNING: 'helm template' cannot resolve lookup() calls (offline render)."
	@echo "MongoDB passwords in this output will be freshly generated random values,"
	@echo "not the ones actually stored in the cluster. Use 'make dry-run' to check"
	@echo "against a live cluster instead."
	helm template $(RELEASE) $(LOCAL_CHART) $(VALUES)

.PHONY: dry-run
dry-run:
	# NOTE: --dry-run=server is required (not plain --dry-run) so that
	# the `lookup` calls in mongo-secret.yaml resolve against the live
	# cluster instead of returning empty and regenerating passwords.
	helm upgrade --install \
		$(RELEASE) \
		$(LOCAL_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		$(VALUES) \
		--dry-run=server \
		--debug

.PHONY: package
package:
	helm package $(LOCAL_CHART)

.PHONY: dependency
dependency:
	helm dependency update $(LOCAL_CHART)

.PHONY: check-images
check-images:
	@echo "Checking images in chart $(LOCAL_CHART) ..."
	./scripts/check-images.sh $(LOCAL_CHART)

.PHONY: rotate-mongo-password
rotate-mongo-password:
	NAMESPACE=$(NAMESPACE) \
	MONGO_POD=$(MONGO_POD) \
	MONGO_SECRET_NAME=$(MONGO_SECRET_NAME) \
	MONGO_PASSWORD_LENGTH=$(MONGO_PASSWORD_LENGTH) \
	MONGO_RESTART_TARGETS=$(MONGO_RESTART_TARGETS) \
	./scripts/rotate-mongo-password.sh

.PHONY: test-mongo-liveness
test-mongo-liveness:
	NAMESPACE=$(NAMESPACE) \
	RELEASE=$(RELEASE) \
	LOCAL_CHART=$(LOCAL_CHART) \
	VALUES="$(VALUES)" \
	STATEFULSET=$(MONGO_STATEFULSET) \
	MONGO_POD=$(MONGO_POD) \
	MONGO_CONTAINER=$(MONGO_CONTAINER) \
	LIVENESS_TEST_TIMEOUT=$(LIVENESS_TEST_TIMEOUT) \
	./scripts/test-mongo-liveness.sh