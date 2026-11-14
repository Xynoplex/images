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
BROWSER_VERSION="${SEMIONT_BROWSER_VERSION:-$(python3 -c 'import json; print(json.load(open("browser/package.publish.json"))["version"])')}"

languages=()
for service in "$@"; do
  case "$service" in
    browser) languages+=(typescript) ;;
    librarian|smelter|weaver|worker) languages+=(python) ;;
    gateway|archivist|dispatcher) languages+=(rust) ;;
    *) usage ;;
  esac
done
languages_csv="$(printf '%s\n' "${languages[@]}" | sort -u | paste -sd, -)"
IFS=, read -r -a selected_languages <<< "$languages_csv"
bundle="$(bash "$REPO_ROOT/scripts/prepare-sdk-artifacts.sh" "${selected_languages[@]}")"
bundle_dir=".local/sdk-artifacts/$(basename "$bundle")"
bundle_id="$(basename "$bundle")"
mkdir -p "$bundle_dir"
cp -a "$bundle/." "$bundle_dir/"
if [[ " ${selected_languages[*]} " == *" rust "* ]]; then
  python3 "$REPO_ROOT/scripts/prepare-rust-sdk-artifacts.py" "$bundle_dir" "$bundle_dir/cargo-local"
fi

for service in "$@"; do
  case "$service" in
    gateway|archivist|dispatcher) args=(--build-arg "RUST_TOOLCHAIN=$RUST_TOOLCHAIN" --build-arg "SDK_ARTIFACT_BUNDLE=$bundle_id") ;;
    librarian|smelter|weaver|worker) args=(--build-arg "PYTHON_FLOOR=$PYTHON_FLOOR" --build-arg "SDK_ARTIFACT_BUNDLE=$bundle_id") ;;
    browser) args=(--build-arg "SEMIONT_BROWSER_VERSION=$BROWSER_VERSION") ;;
    *) usage ;;
  esac
  if [[ "$service" == browser ]]; then
    bash "$REPO_ROOT/scripts/build-browser-package.sh" "$REPO_ROOT/$bundle_dir"
    args+=(--build-arg "BROWSER_PACKAGE_DIR=.local/browser-package")
  fi
  tag="ghcr.io/xynoplex/xynoplex-$service:local"
  echo "Building $tag using $RT"
  "$RT" build "${args[@]}" --file "$service/Dockerfile" --tag "$tag" .
done

echo "Built image version $VERSION locally. No image was pushed."
