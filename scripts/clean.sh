#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/container-runtime.sh"
runtime="$(detect_container_runtime)"
for name in gateway archivist dispatcher browser librarian smelter weaver worker; do
  "$runtime" image rm "ghcr.io/xynoplex/xynoplex-$name:local" >/dev/null 2>&1 || true
done
STATE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/xynoplex-images/local"
rm -rf "$STATE_ROOT/python"
rm -rf "$ROOT/.local/shared-python-packages"
