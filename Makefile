.DEFAULT_GOAL := build

# The Rust images share one compile of the Rust workspace; the Python images, the shared Python packages.
RUST_IMAGES := gateway archivist dispatcher
PYTHON_IMAGES := librarian smelter weaver worker
IMAGE_NAMES := $(RUST_IMAGES) browser $(PYTHON_IMAGES)

.PHONY: help build shared clean $(IMAGE_NAMES) stack-up e2e stack-down smoke

# `make help` prints the `##` lines below, in order (scripts/make-help.awk).
##@ Xynoplex Images: make [target] [VARIABLE=value ...]
##@ Variables
## CONTAINER_RUNTIME=name: container|docker|podman; else the first to respond
CONTAINER_RUNTIME ?=
## SDK_REPO=path: The SDK checkout that builds and resolves artifacts when SDK_ARTIFACTS is unset
SDK_REPO ?= ../sdk
## SDK_ARTIFACTS=path: Use and verify this SDK artifact bundle instead
## SEMIONT_BROWSER_VERSION=version: The Browser package version; else browser/package.publish.json's
## SMOKE_TAG=tag: The image tag stack-up and smoke run
SMOKE_TAG ?= local
## E2E_SCRIPT=name: The E2E npm script
E2E_SCRIPT ?= test:ci
## E2E_MODEL=id: The E2E KB's model; else the one init picks
E2E_MODEL ?=
## E2E_ARGS=words: Extra Playwright arguments, after --
E2E_ARGS ?=
## XYNAUT=path: The xynaut executable; else the one on PATH
XYNAUT ?=
export CONTAINER_RUNTIME SDK_REPO XYNAUT

help:
	@awk -v list="$(IMAGE_NAMES)" -f scripts/make-help.awk Makefile Makefile

##@ Build locally (images are not pushed)
## build: Every image
build: shared
	@./scripts/build-session.sh all

## shared: The shared Python distributions the Python images install, under the XDG cache's xynoplex-images/local/python/packages
shared:
	@./scripts/build-shared-python.sh

## <image>: One image: <list>
$(IMAGE_NAMES):
	@./scripts/build-session.sh "$@"

$(PYTHON_IMAGES): shared

##@ Stack and E2E
## stack-up: Boot and check the SMOKE_TAG images, and leave them up
stack-up:
	@./tests/stack/smoke-stack.sh up "$(SMOKE_TAG)"

## e2e: Run E2E_SCRIPT against a fresh KB beside the stack
e2e:
	@./tests/stack/smoke-stack.sh e2e --script "$(E2E_SCRIPT)" $(if $(strip $(E2E_MODEL)),--model "$(E2E_MODEL)") $(if $(strip $(E2E_ARGS)),-- $(E2E_ARGS))

## stack-down: Stop the stack and remove failed E2E KBs
stack-down:
	@./tests/stack/smoke-stack.sh down

# A standalone `make e2e` leaves a failed KB for inspection. This combined
# target is the self-cleaning stack smoke flow and always attempts teardown.
## smoke: stack-up, e2e and stack-down, tearing down whatever e2e did
smoke:
	@status=0; down_status=0; \
	./tests/stack/smoke-stack.sh up "$(SMOKE_TAG)" || status=$$?; \
	if [ $$status -eq 0 ]; then \
	  ./tests/stack/smoke-stack.sh e2e --script "$(E2E_SCRIPT)" $(if $(strip $(E2E_MODEL)),--model "$(E2E_MODEL)") $(if $(strip $(E2E_ARGS)),-- $(E2E_ARGS)) || status=$$?; \
	fi; \
	./tests/stack/smoke-stack.sh down || down_status=$$?; \
	if [ $$status -ne 0 ]; then exit $$status; else exit $$down_status; fi

##@ Clean
## clean: Remove local image tags and shared-package distributions; keep staged SDK artifacts
clean:
	@./scripts/clean.sh
