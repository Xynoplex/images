# The Archivist image: the binary, built here from the repository, and nothing
# of its source — no .rs, no Cargo files, no target/, no toolchain, no protocol/specs/
# (the spec is compiled into the binary), and no Node. Nothing is built,
# installed or fetched when the container starts: the entrypoint execs the binary.
#
# Built from the repository root, with the toolchain
# rust-toolchain.toml names — the one place it is written:
#
#   --build-arg RUST_TOOLCHAIN=$(packages/rust/scripts/rust-toolchain.sh)
#
# There is no default: without it the first FROM names no image and the build
# stops, rather than building with a toolchain nothing pinned.
ARG RUST_TOOLCHAIN
ARG SDK_ARTIFACT_BUNDLE

# The build stages, from here to the runtime stage, are the same in each Rust
# service's Dockerfile (lint:rust-images): they build every service's binary,
# so an image built after, or beside, another reuses them instead of compiling
# the workspace again.
FROM rust:${RUST_TOOLCHAIN}-alpine AS chef
# make builds jemalloc, the allocator tikv-jemalloc-sys compiles into the binary.
RUN apk add --no-cache make
# cargo-auditable writes the crates the binary links into the binary itself,
# which is how the image scan (Trivy) sees them in an image with no Cargo.lock.
RUN cargo install cargo-auditable --locked --version 0.7.6
# cargo-chef compiles the workspace's dependencies without its source, in a
# layer whose only inputs are the manifests, the lockfile and the SDK's crates.
RUN cargo install cargo-chef --locked --version 0.1.78
WORKDIR /build

# The workspace's source, and the recipe cargo-chef reads from it: its members'
# manifests and the lockfile. A change to the source alone leaves the recipe as
# it was.
FROM chef AS planner
COPY version.json ./
COPY protocol/specs/src protocol/specs/src
# The workspace (packages/rust/Cargo.toml): cargo loads every member
# to build any one of them, so each member's crate is copied.
COPY packages/rust/Cargo.toml packages/rust/Cargo.lock packages/rust/
COPY archivist/Cargo.toml archivist/
COPY archivist/src archivist/src
COPY archivist/record/Cargo.toml archivist/record/
COPY archivist/record/src archivist/record/src
COPY archivist/staging/Cargo.toml archivist/staging/
COPY archivist/staging/src archivist/staging/src
COPY gateway/Cargo.toml gateway/
COPY gateway/src gateway/src
COPY dispatcher/Cargo.toml dispatcher/
COPY dispatcher/src dispatcher/src
COPY dispatcher/handlers/Cargo.toml dispatcher/handlers/
COPY dispatcher/handlers/src dispatcher/handlers/src
COPY dispatcher/jetstream/Cargo.toml dispatcher/jetstream/build.rs dispatcher/jetstream/
COPY dispatcher/jetstream/src dispatcher/jetstream/src
COPY packages/rust/core/Cargo.toml packages/rust/core/build.rs packages/rust/core/
COPY packages/rust/core/src packages/rust/core/src
COPY packages/rust/http-service/Cargo.toml packages/rust/http-service/
COPY packages/rust/http-service/src packages/rust/http-service/src
COPY packages/rust/observability/Cargo.toml packages/rust/observability/
COPY packages/rust/observability/src packages/rust/observability/src
WORKDIR /build/packages/rust
RUN cargo chef prepare --recipe-path /recipe.json

# The dependencies compile first, from the recipe, and the binaries after,
# from the source. A spec that does not compile fails here, in the build
# scripts, never at boot. The registry and target/ stay in the layers, which
# is what a build cache keeps; the last step removes target/ once the binaries
# are out of it.
FROM chef AS builder
ARG SDK_ARTIFACT_BUNDLE
COPY .local/sdk-artifacts/${SDK_ARTIFACT_BUNDLE}/cargo-local /sdk/cargo-local
COPY .local/sdk-artifacts/${SDK_ARTIFACT_BUNDLE}/cargo-local/config.toml /usr/local/cargo/config.toml
COPY --from=planner /recipe.json /recipe.json
WORKDIR /build/packages/rust
# No --locked: cargo-chef 0.1.78 writes each member's lockfile entry as 0.0.1
# and leaves its manifest, which names no version, at cargo's 0.0.0, so the
# skeleton's lockfile is never current. The build below is --locked against
# the repository's Cargo.lock.
RUN cargo chef cook --release -p xynolog-archivist -p xynolog-dispatcher -p xynolog-gateway --recipe-path /recipe.json
COPY --from=planner /build /build
RUN cargo auditable build --release --locked -p xynolog-archivist -p xynolog-dispatcher -p xynolog-gateway && \
    cp target/release/xynolog-archivist target/release/xynolog-dispatcher target/release/xynolog-gateway / && \
    rm -rf target

FROM alpine:3.24
# git is the Archivist's staging driver's: a knowledge base that syncs git has
# its changes staged with it, and this is the one image that runs it. The
# mounted knowledge base is owned by a host uid that need not be this image's
# user, and git refuses a tree whose owner is not the caller's
# (CVE-2022-24765) unless told to trust it; --system writes /etc/gitconfig,
# which applies to every user.
RUN apk upgrade --no-cache && apk add --no-cache tini git && \
    git config --system --add safe.directory /kb

# The uid the launcher's state mount is written as, as in every service image.
RUN addgroup --system --gid 1001 xynolog && \
    adduser --system --uid 1001 --ingroup xynolog --home /home/xynolog xynolog

COPY --from=builder /xynolog-archivist /usr/local/bin/xynolog-archivist
COPY LICENSE archivist/NOTICE /home/xynolog/
COPY shared/supervise.sh /usr/local/bin/supervise.sh
COPY shared/boot.sh /usr/local/bin/boot.sh

# The knowledge base is mounted here, and is where git is run.
WORKDIR /kb
RUN chown xynolog:xynolog /kb

USER xynolog

EXPOSE 24103

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:24103/health || exit 1

ENV SUPERVISE_NAME=archivist \
    SUPERVISE_PROBE=http://localhost:24103/health
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/boot.sh"]
# --config names where the launcher mounts the Archivist's document; the
# launcher's census (TestConfigDocumentsAreWhereTheImagesLook) reads it here.
CMD ["/usr/local/bin/xynolog-archivist", "--config", "/etc/xynolog/archivist.json"]
