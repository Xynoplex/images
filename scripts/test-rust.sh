#!/usr/bin/env bash
# test-rust.sh — the Rust workspace's checks (`make test-rust`): its format,
# its lints, its tests and its dependency boundaries
# (packages/rust/scripts/check-dependency-boundaries.sh), at packages/rust.
#
# They run in the toolchain's container (rust:<channel>-bookworm, the channel
# rust-toolchain.toml names), on a copy of the checkout, against the SDK's
# crates from the SDK artifact bundle, staged as the crates job and the Rust
# images stage them. Every check runs, and the run fails if any did.
#
# Cargo's registry and target directory outlive the container, under the XDG
# cache's xynolog-images/rust, so a run compiles only what changed since the
# last one. CI's rust job caches that directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
source "$ROOT/build-tools/container-runtime.sh"
RT="$(detect_container_runtime)"
RUST_TOOLCHAIN="$(packages/rust/scripts/rust-toolchain.sh)"

bundle="$(bash "$ROOT/build-tools/prepare-sdk-artifacts.sh" rust)"
cargo_local="$(mktemp -d "${TMPDIR:-/tmp}/xynolog-rust-sdk.XXXXXX")"
trap 'rm -rf "$cargo_local"' EXIT
python3 "$ROOT/scripts/prepare-rust-sdk-artifacts.py" "$bundle" "$cargo_local"

cache="${XDG_CACHE_HOME:-$HOME/.cache}/xynolog-images/rust"
mkdir -p "$cache/registry" "$cache/target"

"$RT" run --rm --memory 6g \
  --volume "$ROOT:/source:ro" \
  --volume "$cargo_local:/sdk/cargo-local:ro" \
  --volume "$cache/registry:/usr/local/cargo/registry" \
  --volume "$cache/target:/target" \
  --env CARGO_TARGET_DIR=/target \
  "rust:$RUST_TOOLCHAIN-bookworm" \
  bash -euc '
    mkdir /tmp/images
    tar -C /source --exclude=.git --exclude=target --exclude=.claude --exclude=.local --exclude=node_modules -cf - . \
      | tar -C /tmp/images -xf -
    cp /sdk/cargo-local/config.toml /usr/local/cargo/config.toml
    cd /tmp/images/packages/rust
    status=0
    cargo fmt --all --check || status=1
    cargo clippy --workspace --all-targets --all-features --locked -- -D warnings || status=1
    cargo test --workspace --all-features --locked --no-fail-fast || status=1
    bash scripts/check-dependency-boundaries.sh || status=1
    exit "$status"'
