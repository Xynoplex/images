# Xynoplex Images

This repository builds and publishes the Xynoplex service and Browser container images for macOS, Linux, and Windows container hosts.

## Images

| Image | Source | Default port | Purpose |
| --- | --- | ---: | --- |
| `ghcr.io/xynoplex/xynoplex-gateway` | [gateway](gateway/) | 4000 | Authenticated API and content gateway |
| `ghcr.io/xynoplex/xynoplex-archivist` | [archivist](archivist/) | 24103 | Record storage and browse operations |
| `ghcr.io/xynoplex/xynoplex-dispatcher` | [dispatcher](dispatcher/) | 24105 | Job queue and lifecycle operations |
| `ghcr.io/xynoplex/xynoplex-librarian` | [librarian](librarian/) | 24104 | Search and context assembly |
| `ghcr.io/xynoplex/xynoplex-smelter` | [smelter](smelter/) | 24101 | Content extraction and embedding |
| `ghcr.io/xynoplex/xynoplex-weaver` | [weaver](weaver/) | 24102 | Knowledge graph projection |
| `ghcr.io/xynoplex/xynoplex-worker` | [worker](worker/) | 24100 | Asynchronous detection, generation, and inference |
| `ghcr.io/xynoplex/xynoplex-browser` | [browser](browser/) | 3000 | Browser user interface |

## Build locally

A root Makefile is the primary build interface. Install Docker, Podman, or Apple Container, then run:

```sh
make help
make local
make shared
make image NAME=gateway
make clean
```

`make shared` builds the four private Python distributions in `shared/python/` (`graph`, `vectors`, `inference`, and `service`) into `.local/shared-python-packages/`. Builds are local and are not pushed. `CONTAINER_RUNTIME` can select an installed runtime explicitly, for example `CONTAINER_RUNTIME=docker make local`.

## Repository layout

Each top-level service directory contains its image source and Dockerfile. `shared/` contains runtime files copied into images; `shared/python/` contains the Python graph, vector, inference, and service libraries shared by the Python images. `e2e/`, `tests/`, and `scripts/` hold image integration coverage and tooling.

`packages/` and `protocol/` currently retain the Rust and Python SDK/build inputs these images consume. They are temporary build inputs pending the separate package and protocol repositories.

## Publishing

Images are published to GitHub Container Registry by the workflows in `.github/workflows/`. Service images and the Browser image have separate release workflows. Published images are multi-architecture OCI images and use the `xynoplex-*` image names.
