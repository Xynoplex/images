#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/scripts/container-runtime.sh"
RUNTIME="$(detect_container_runtime)"
OUTPUT="$ROOT/.local/shared-python-packages"
PACKAGES=(graph vectors inference service)

mkdir -p "$OUTPUT"
for package in "${PACKAGES[@]}"; do rm -rf "$OUTPUT/$package"; done

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
      uv build --out-dir "/artifacts/$package"
    done
  '

printf '\nShared Python distributions are under:\n  %s\n' "$OUTPUT"
