.PHONY: help local build shared image clean gateway archivist dispatcher browser librarian smelter weaver worker
.DEFAULT_GOAL := build

IMAGE_NAMES := gateway archivist dispatcher browser librarian smelter weaver worker

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
	  'Inputs:' \
	  '  SDK_REPO=<path>       SDK checkout used to resolve/build artifacts (default: ../sdk)' \
	  '  SDK_ARTIFACTS=<path>  Use and verify an existing SDK artifact bundle' \
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
