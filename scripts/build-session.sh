#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

usage() {
  echo "Usage: $0 [all|gateway|archivist|dispatcher|browser|librarian|smelter|weaver|worker] ..." >&2
  exit 2
}

if [[ $# -eq 0 ]]; then set -- all; fi
if [[ "$1" == all ]]; then
  [[ $# -eq 1 ]] || usage
  set -- gateway archivist dispatcher browser librarian smelter weaver worker
fi

source "$REPO_ROOT/scripts/container-runtime.sh"
RT="$(detect_container_runtime)"
RUST_TOOLCHAIN="$(packages/rust/scripts/rust-toolchain.sh)"
PYTHON_FLOOR="$(shared/python/python-floor.sh)"
VERSION="$(python3 -c 'import json; print(json.load(open("version.json"))["version"])')"
BROWSER_VERSION="${SEMIONT_BROWSER_VERSION:-$(python3 -c 'import json; print(json.load(open("version.json"))["packages"]["semiont-browser"]["version"])')}"

for service in "$@"; do
  case "$service" in
    gateway|archivist|dispatcher) args=(--build-arg "RUST_TOOLCHAIN=$RUST_TOOLCHAIN") ;;
    librarian|smelter|weaver|worker) args=(--build-arg "PYTHON_FLOOR=$PYTHON_FLOOR") ;;
    browser) args=(--build-arg "SEMIONT_BROWSER_VERSION=$BROWSER_VERSION") ;;
    *) usage ;;
  esac
  tag="ghcr.io/xynoplex/xynoplex-$service:local"
  echo "Building $tag using $RT"
  "$RT" build "${args[@]}" --file "$service/Dockerfile" --tag "$tag" .
done

echo "Built image version $VERSION locally. No image was pushed."
