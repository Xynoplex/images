#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SDK_BUNDLE_DIR="${1:?Usage: build-browser-package.sh <verified-sdk-bundle-directory>}"
[[ -f "$SDK_BUNDLE_DIR/artifacts.json" ]] || {
  echo "SDK artifact manifest not found: $SDK_BUNDLE_DIR/artifacts.json" >&2
  exit 2
}
mkdir -p "$ROOT/.local/browser-package" "$ROOT/.local/browser-lock"

source "$ROOT/build-tools/container-runtime.sh"
RUNTIME="$(detect_container_runtime)"
"$RUNTIME" run --rm \
  --volume "$ROOT:/source" \
  --volume "$SDK_BUNDLE_DIR:/sdk-bundle:ro" \
  --workdir /tmp \
  node:26-bookworm bash -euc '
    mkdir -p /tmp/browser /tmp/browser-publish
    mkdir -p /packages/typescript/react-ui
    tar -xzf /sdk-bundle/typescript/xynoplex-react-ui-*.tgz \
      -C /packages/typescript/react-ui --strip-components=1 package/translations
    cp -a /source/browser/. /tmp/browser/
    python3 - /tmp/browser/package.json /sdk-bundle/artifacts.json <<'PY'
import json
import sys
from pathlib import Path

package_path, manifest_path = map(Path, sys.argv[1:])
package = json.loads(package_path.read_text())
manifest = json.loads(manifest_path.read_text())
for artifact in manifest["artifacts"]:
    if artifact["ecosystem"] == "npm":
        package["dependencies"][artifact["package"]] = (
            "file:/sdk-bundle"
            + "/" + artifact["path"]
        )
package_path.write_text(json.dumps(package, indent=2) + "\n")
PY
    cd /tmp/browser
    npm install --no-audit --no-fund
    npm install-scripts approve --all --no-allow-scripts-pin
    npm rebuild
    npm run build
    # The lock this install resolved, for the advisory scan; nothing commits one.
    cp /tmp/browser/package-lock.json /source/.local/browser-lock/package-lock.json
    cp /source/browser/server.js /tmp/browser-publish/server.js
    cp /source/browser/package.publish.json /tmp/browser-publish/package.json
    cp -a /tmp/browser/dist /tmp/browser-publish/dist
    cd /tmp
    npm pack /tmp/browser-publish --pack-destination /source/.local/browser-package
  '
