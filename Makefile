.PHONY: help local build image clean gateway archivist dispatcher browser librarian smelter weaver worker
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
	  '  make <name>           Build one image: gateway, archivist, dispatcher,' \
	  '                        browser, librarian, smelter, weaver, or worker' \
	  '  make image NAME=<name> Build one image: gateway, archivist, dispatcher,' \
	  '                        browser, librarian, smelter, weaver, or worker' \
	  '' \
	  'Inputs:' \
	  '  SDK_REPO=<path>       SDK checkout used to resolve/build artifacts (default: ../sdk)' \
	  '  SDK_ARTIFACTS=<path>  Use and verify an existing SDK artifact bundle' \
	  '  CONTAINER_RUNTIME=<cmd> Select container, docker, or podman explicitly' \
	  '  SEMIONT_BROWSER_VERSION=<version> Override the Browser package version' \
	  '' \
	  'Clean:' \
	  '  make clean            Remove the eight local image tags; retain staged SDK artifacts'

build: local

local:
	@./scripts/build-session.sh all

image:
	@test -n "$(NAME)" || { echo "Set NAME to one of: $(IMAGE_NAMES)" >&2; exit 2; }
	@./scripts/build-session.sh "$(NAME)"

$(IMAGE_NAMES):
	@./scripts/build-session.sh "$@"

clean:
	@./scripts/clean.sh
