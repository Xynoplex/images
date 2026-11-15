#!/bin/sh
# Print the oldest Python supported by the pinned SDK wheel's metadata.
set -eu
cd "$(dirname "$0")/../.."

bundle=${1:-}
if [ -z "$bundle" ]; then
  echo "Usage: $0 STAGED_SDK_ARTIFACT_BUNDLE" >&2
  exit 2
fi

python3 - "$bundle" <<'PY'
import email.parser
import pathlib
import re
import sys
import zipfile

wheel_dir = pathlib.Path(sys.argv[1]) / "python"
wheels = sorted(wheel_dir.glob("xynolog-*-py3-none-any.whl"))
if len(wheels) != 1:
    raise SystemExit(f"python-floor.sh: expected one xynolog wheel in {wheel_dir}, found {len(wheels)}")
with zipfile.ZipFile(wheels[0]) as wheel:
    metadata_path = next((name for name in wheel.namelist() if name.endswith(".dist-info/METADATA")), None)
    if metadata_path is None:
        raise SystemExit(f"python-floor.sh: no wheel METADATA in {wheels[0]}")
    metadata = email.parser.BytesParser().parsebytes(wheel.read(metadata_path))
requirement = metadata.get("Requires-Python", "")
match = re.fullmatch(r">=([0-9]+\.[0-9]+)(?:,.*)?", requirement)
if not match:
    raise SystemExit(f"python-floor.sh: unsupported Requires-Python value {requirement!r} in {wheels[0]}")
print(match.group(1))
PY
