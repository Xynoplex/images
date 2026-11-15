#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/build-tools/container-runtime.sh"
RUNTIME="$(detect_container_runtime)"
STATE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/xynoplex-images/local"
OUTPUT="$STATE_ROOT/python/packages"
MANIFEST="$STATE_ROOT/python/source.sha256"
PACKAGES=(graph vectors inference service)

source_hash() {
  find "${PACKAGES[@]/#/$ROOT/shared/python/}" -type f \
    ! -path '*/__pycache__/*' ! -name '*.pyc' -print0 |
    sort -z |
    xargs -0 shasum -a 256 |
    shasum -a 256 | awk '{print $1}'
}

current_hash="$(source_hash)"
if [[ "${1:-}" == --ensure ]]; then
  fresh=true
  [[ -f "$MANIFEST" && "$(cat "$MANIFEST")" == "$current_hash" ]] || fresh=false
  shopt -s nullglob
  for package in "${PACKAGES[@]}"; do
    wheels=("$OUTPUT/semiont_${package}-"*.whl)
    (( ${#wheels[@]} == 1 )) || fresh=false
  done
  if [[ "$fresh" == true ]]; then
    printf 'Shared Python distributions are current:\n  %s\n' "$OUTPUT"
    exit 0
  fi
elif [[ $# -ne 0 ]]; then
  echo "Usage: $0 [--ensure]" >&2
  exit 2
fi

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
printf '%s\n' "$current_hash" > "$MANIFEST"
