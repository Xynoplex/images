.PHONY: help local build image clean

IMAGE_NAMES := gateway archivist dispatcher browser librarian smelter weaver worker

help:
	@echo "Xynoplex Images"
	@echo "  make local        Build all eight images locally"
	@echo "  make build        Build all eight images locally"
	@echo "  make image NAME=gateway   Build one image"
	@echo "  make clean        Remove local image tags"

build: local

local:
	@./scripts/build-session.sh all

image:
	@test -n "$(NAME)" || { echo "Set NAME to one of: $(IMAGE_NAMES)" >&2; exit 2; }
	@./scripts/build-session.sh "$(NAME)"

clean:
	@./scripts/clean.sh
