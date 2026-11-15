#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/scripts/container-runtime.sh"
RUNTIME="$(detect_container_runtime)"
STATE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/xynoplex-images/local"
OUTPUT="$STATE_ROOT/python/packages"
PACKAGES=(graph vectors inference service)

# Remove artifacts from the previous checkout-local location.
rm -rf "$ROOT/.local/shared-python-packages"
mkdir -p "$OUTPUT"
for package in "${PACKAGES[@]}"; do
  rm -f "$OUTPUT/semiont_${package}-"*.tar.gz "$OUTPUT/semiont_${package}-"*.whl
done

printf '==> Building shared Python distributions with uv 0.13.7\n'
"$RUNTIME" run --rm \
  --volume "$ROOT:/workspace:ro" \
  --volume "$OUTPUT:/artifacts" \
  --workdir /workspace \
  python:3.12-slim sh -euc '
    python -m pip install --disable-pip-version-check --no-cache-dir --root-user-action=ignore uv==0.13.7
    for package in graph vectors inference service; do
      echo "==> Building shared Python package: $package"
      cd "/workspace/shared/python/$package"
      uv build --out-dir /artifacts
    done
  '

printf '\nShared Python distributions are under:\n  %s\n' "$OUTPUT"
