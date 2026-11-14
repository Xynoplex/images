#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$ROOT"
bundle="${SDK_ARTIFACTS:-}"
[[ -n "$bundle" && -f "$bundle/artifacts.json" ]] || {
  echo 'Set SDK_ARTIFACTS to a verified SDK artifact bundle.' >&2
  exit 2
}
[[ $# -gt 0 ]] || { echo 'Usage: stage-sdk-artifacts.sh <language>...' >&2; exit 2; }

expected_protocol="$(git ls-tree HEAD protocol | awk '{print $3}')"
actual_protocol="$(git -C protocol rev-parse HEAD 2>/dev/null || true)"
[[ -n "$expected_protocol" && "$actual_protocol" == "$expected_protocol" ]] || {
  echo "Protocol submodule does not match the Images pin (${expected_protocol:-missing})." >&2
  exit 2
}
[[ -z "$(git -C protocol status --porcelain --untracked-files=all)" ]] || {
  echo 'Protocol submodule has local changes; pin the intended Protocol revision before building.' >&2
  exit 2
}

verify_args=(--protocol-commit "$expected_protocol")
for language in "$@"; do verify_args+=(--language "$language"); done
python3 "$bundle/tools/verify-artifact-bundle.py" "$bundle" "${verify_args[@]}" >/dev/null

bundle_id="$(basename "$bundle")"
bundle_dir=".local/sdk-artifacts/$bundle_id"
mkdir -p "$bundle_dir"
bundle_path="$(cd "$bundle" && pwd -P)"
stage_path="$(cd "$bundle_dir" && pwd -P)"
if [[ "$bundle_path" != "$stage_path" ]]; then
  cp -a "$bundle/." "$bundle_dir/"
fi
if [[ " $* " == *" rust "* ]]; then
  python3 scripts/prepare-rust-sdk-artifacts.py "$bundle_dir" "$bundle_dir/cargo-local"
fi
printf '%s\n' "$bundle_id"
