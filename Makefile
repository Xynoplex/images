.PHONY: help local build shared image clean gateway archivist dispatcher browser librarian smelter weaver worker stack-up e2e stack-down smoke
.DEFAULT_GOAL := build

IMAGE_NAMES := gateway archivist dispatcher browser librarian smelter weaver worker
SMOKE_TAG ?= local
E2E_SCRIPT ?= test:ci
E2E_MODEL ?=
E2E_ARGS ?=
CONTAINER_RUNTIME ?=
XYNAUT ?=
export CONTAINER_RUNTIME XYNAUT

help:
	@printf '%s\n' \
	  'Xynoplex Images' \
	  '' \
	  'Build locally (images are not pushed):' \
	  '  make                  Build all eight images (default target)' \
	  '  make local            Same as make' \
	  '  make build            Same as make' \
	  '  make shared           Build the shared Python distributions; Python image builds use these wheels' \
	  '  make gateway          Build the Gateway image' \
	  '  make archivist        Build the Archivist image' \
	  '  make dispatcher       Build the Dispatcher image' \
	  '  make browser          Build the Browser image' \
	  '  make librarian        Build the Librarian image' \
	  '  make smelter          Build the Smelter image' \
	  '  make weaver           Build the Weaver image' \
	  '  make worker           Build the Worker image' \
	  '  make image NAME=<name> Build one image using any name above' \
	  '' \
	  'Stack and E2E:' \
	  '  make stack-up         Boot and check SMOKE_TAG images; leave them up' \
	  '  make e2e              Run E2E_SCRIPT against a fresh KB beside the stack' \
	  '  make stack-down       Stop the stack and clean up failed E2E KBs' \
	  '  make smoke            Run stack-up, e2e, and stack-down' \
	  '' \
	  'Inputs:' \
	  '  SDK_REPO=<path>       SDK checkout used to resolve/build artifacts (default: ../sdk)' \
	  '  SDK_ARTIFACTS=<path>  Use and verify an existing SDK artifact bundle' \
	  '  SMOKE_TAG=tag         Image tag for stack-up and smoke (default: local)' \
	  '  E2E_SCRIPT=name       E2E npm script (default: test:ci)' \
	  '  E2E_MODEL=id          Model for the E2E KB (default: init model)' \
	  '  E2E_ARGS=words        Extra Playwright arguments after --' \
	  '  XYNAUT=<path>          xynaut executable (default: search PATH)' \
	  '  CONTAINER_RUNTIME=<cmd> Select container, docker, or podman explicitly' \
	  '  SEMIONT_BROWSER_VERSION=<version> Override the Browser package version' \
	  '  Shared Python output   XDG cache: xynoplex-images/local/python/packages' \
	  '' \
	  'Clean:' \
	  '  make clean            Remove local image tags and shared-package distributions; retain staged SDK artifacts'

build: local

local: shared
	@./scripts/build-session.sh all

shared:
	@./scripts/build-shared-python.sh

image:
	@test -n "$(NAME)" || { echo "Set NAME to one of: $(IMAGE_NAMES)" >&2; exit 2; }
	@./scripts/build-session.sh "$(NAME)"

$(IMAGE_NAMES):
	@./scripts/build-session.sh "$@"

librarian smelter weaver worker: shared

clean:
	@./scripts/clean.sh

stack-up:
	@./tests/stack/smoke-stack.sh up "$(SMOKE_TAG)"

e2e:
	@./tests/stack/smoke-stack.sh e2e --script "$(E2E_SCRIPT)" $(if $(strip $(E2E_MODEL)),--model "$(E2E_MODEL)") $(if $(strip $(E2E_ARGS)),-- $(E2E_ARGS))

stack-down:
	@./tests/stack/smoke-stack.sh down

# A standalone `make e2e` leaves a failed KB for inspection. This combined
# target is the self-cleaning stack smoke flow and always attempts teardown.
smoke:
	@status=0; down_status=0; \
	./tests/stack/smoke-stack.sh up "$(SMOKE_TAG)" || status=$$?; \
	if [ $$status -eq 0 ]; then \
	  ./tests/stack/smoke-stack.sh e2e --script "$(E2E_SCRIPT)" $(if $(strip $(E2E_MODEL)),--model "$(E2E_MODEL)") $(if $(strip $(E2E_ARGS)),-- $(E2E_ARGS)) || status=$$?; \
	fi; \
	./tests/stack/smoke-stack.sh down || down_status=$$?; \
	if [ $$status -ne 0 ]; then exit $$status; else exit $$down_status; fi
