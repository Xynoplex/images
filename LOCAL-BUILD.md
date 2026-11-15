# Local image builds

The root [Makefile](Makefile) is the supported build interface:

```sh
make help
make local
make shared
make image NAME=worker
make clean
```

`make local` builds the eight images from their Dockerfiles using Docker, Podman, or Apple Container. It detects an available runtime, preferring Apple Container, then Docker, then Podman. Set `CONTAINER_RUNTIME` to select one explicitly.

`make shared` builds the four Python distributions in `shared/python/` (graph, vectors, inference, and service) with the pinned uv container. It writes the wheel and source archive files to `.local/shared-python-packages/` without building any container images.

Each image is tagged locally as `ghcr.io/xynoplex/xynoplex-<name>:local`. Builds do not push images. `make clean` removes those local tags and the local shared-package distributions, while retaining staged SDK artifacts.

The Dockerfiles use the repository root as build context because they copy shared runtime files and the current SDK/protocol build inputs as well as each service's source. The SDK and protocol source directories are temporary build dependencies while their separate repositories are being prepared.
