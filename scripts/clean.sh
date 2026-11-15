#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/build-tools/container-runtime.sh"
runtime="$(detect_container_runtime)"
images="$("$ROOT/scripts/image-groups.sh" IMAGE_NAMES)"
for name in $images; do
  "$runtime" image rm "ghcr.io/xynolog/xynolog-$name:local" >/dev/null 2>&1 || true
done
STATE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/xynolog-images/local"
rm -rf "$STATE_ROOT/python"
rm -rf "$ROOT/.local/shared-python-packages"
