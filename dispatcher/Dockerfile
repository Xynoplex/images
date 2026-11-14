# The dispatcher image: the binary, built here from the repository, and nothing
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

FROM rust:${RUST_TOOLCHAIN}-alpine AS builder
ARG SDK_ARTIFACT_BUNDLE
# make builds jemalloc, the allocator tikv-jemalloc-sys compiles into the binary.
RUN apk add --no-cache make
# cargo-auditable writes the crates the binary links into the binary itself,
# which is how the image scan (Trivy) sees them in an image with no Cargo.lock.
RUN cargo install cargo-auditable --locked --version 0.7.6
WORKDIR /build
COPY .local/sdk-artifacts/${SDK_ARTIFACT_BUNDLE}/cargo-local /sdk/cargo-local
COPY .local/sdk-artifacts/${SDK_ARTIFACT_BUNDLE}/cargo-local/config.toml /usr/local/cargo/config.toml
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
# The builder stage is the same in each Rust service's Dockerfile
# (lint:rust-images): it builds every service's binary, so an image built
# after, or beside, another reuses its stage instead of compiling the
# workspace again. A spec that does not compile fails here, in the build
# scripts, never at boot.
WORKDIR /build/packages/rust
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/build/packages/rust/target \
    cargo auditable build --release --locked -p semiont-archivist -p semiont-dispatcher -p semiont-gateway && \
    cp target/release/semiont-archivist target/release/semiont-dispatcher target/release/semiont-gateway /

FROM alpine:3.24
RUN apk upgrade --no-cache && apk add --no-cache tini

# The uid the launcher's state mount is written as, as in every service image.
RUN addgroup --system --gid 1001 semiont && \
    adduser --system --uid 1001 --ingroup semiont --home /home/semiont semiont

COPY --from=builder /semiont-dispatcher /usr/local/bin/semiont-dispatcher
COPY LICENSE dispatcher/NOTICE /home/semiont/
COPY shared/supervise.sh /usr/local/bin/supervise.sh
COPY shared/boot.sh /usr/local/bin/boot.sh

USER semiont

EXPOSE 24105

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:24105/health || exit 1

ENV SUPERVISE_NAME=dispatcher \
    SUPERVISE_PROBE=http://localhost:24105/health
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/boot.sh"]
# --config names where the launcher mounts the dispatcher's document; the
# launcher's census (TestConfigDocumentsAreWhereTheImagesLook) reads it here.
CMD ["/usr/local/bin/semiont-dispatcher", "--config", "/etc/semiont/dispatcher.json"]
