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
    tar -xzf /sdk-bundle/typescript/xynolog-react-ui-*.tgz \
      -C /packages/typescript/react-ui --strip-components=1 package/translations
    cp -a /source/browser/. /tmp/browser/
    # Beside the app, as in the repository: the build reads its version there.
    cp /source/version.json /tmp/version.json
    python3 /source/build-tools/prepare-sdk-package.py /sdk-bundle /tmp/browser/package.json
    cd /tmp/browser
    npm install --no-audit --no-fund
    npm install-scripts approve --all --no-allow-scripts-pin
    npm rebuild
    npm run build
    # The lock this install resolved, for the advisory scan; nothing commits one.
    cp /tmp/browser/package-lock.json /source/.local/browser-lock/package-lock.json
    cp /source/browser/server.js /tmp/browser-publish/server.js
    # The package takes the version in version.json, the browser image version.
    node -e '"'"'const fs = require("node:fs"); const p = JSON.parse(fs.readFileSync("/source/browser/package.publish.json", "utf8")); p.version = JSON.parse(fs.readFileSync("/source/version.json", "utf8")).version; fs.writeFileSync("/tmp/browser-publish/package.json", JSON.stringify(p, null, 2) + "\n");'"'"'
    cp -a /tmp/browser/dist /tmp/browser-publish/dist
    cd /tmp
    npm pack /tmp/browser-publish --pack-destination /source/.local/browser-package
  '
