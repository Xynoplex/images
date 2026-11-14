# Local image builds

The root [Makefile](Makefile) is the supported build interface:

```sh
make help
make local
make image NAME=worker
make clean
```

`make local` builds the eight images from their Dockerfiles using Docker, Podman, or Apple Container. It detects an available runtime, preferring Apple Container, then Docker, then Podman. Set `CONTAINER_RUNTIME` to select one explicitly.

Each image is tagged locally as `ghcr.io/xynoplex/xynoplex-<name>:local`. Builds do not push images. `make clean` removes only those local tags.

The Dockerfiles use the repository root as build context because they copy shared runtime files and the current SDK/protocol build inputs as well as each service's source. The SDK and protocol source directories are temporary build dependencies while their separate repositories are being prepared.
