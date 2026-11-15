# Image scripts

`scripts/build-session.sh` powers the Makefile's image build targets. It detects Docker, Podman, or Apple Container and builds selected image directories. `scripts/clean.sh` removes the local tags created by that build. Both, and CI's image grouping, take the images and each one's SDK language from the Makefile's groups through `scripts/image-groups.sh`. CI builds only the images a change affects: `scripts/changed-images.py` reads each image's inputs from its Dockerfile's copies, its language's shared code and what every build reads, and groups the affected ones.

The `check-*-image.sh` scripts and `check-*.mjs` files support image validation and repository maintenance. `shared/boot.sh` and `shared/supervise.sh` are copied into the runtime images by their Dockerfiles.
