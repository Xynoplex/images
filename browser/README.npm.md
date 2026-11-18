# @xynolog/browser

[![npm version](https://img.shields.io/npm/v/@xynolog/browser.svg)](https://www.npmjs.com/package/@xynolog/browser)
[![npm downloads](https://img.shields.io/npm/dm/@xynolog/browser.svg)](https://www.npmjs.com/package/@xynolog/browser)
[![License](https://img.shields.io/npm/l/@xynolog/browser.svg)](https://github.com/xynolog/images/blob/main/LICENSE)

Pre-built Xynolog Browser as a Vite SPA with a zero-dependency Node.js static file server. This package contains the compiled Browser application ready to run with Node.js.

## Running Xynolog

Most people should **not** install this package directly. A Xynolog stack is run with the `xynolog`
launcher — a single static binary that pulls the published container images:

```bash
brew install xynolog/xynolog/xynolog

cd /path/to/your-knowledge-base
xynolog start
```

This package is what the `xynolog-browser` container image runs inside. To run just the browser
against an already-running knowledge base, use the published image directly:

```bash
docker run --publish 3000:3000 -it ghcr.io/xynolog/xynolog-browser:latest
```

## Direct usage

```bash
npm install @xynolog/browser
PORT=3000 node node_modules/@xynolog/browser/server.js
```

The SPA is gateway-agnostic: it connects to knowledge bases chosen in the browser at runtime, so the
only environment variable it needs is `PORT`.

## Links

- [Xynolog GitHub](https://github.com/xynolog/images)
- [Xynolog launcher](https://github.com/xynolog/cli)
- [Documentation](https://github.com/xynolog/images#readme)
