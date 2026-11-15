#!/usr/bin/env node

const { spawnSync } = require('node:child_process');

const command = process.argv[2];
const names = ['gateway', 'archivist', 'dispatcher', 'browser', 'librarian', 'smelter', 'weaver', 'worker'];

function runtime() {
  if (process.env.CONTAINER_RUNTIME) return process.env.CONTAINER_RUNTIME;
  for (const candidate of ['container', 'docker', 'podman']) {
    const result = spawnSync(candidate, ['--version'], { stdio: 'ignore' });
    if (!result.error && result.status === 0) return candidate;
  }
  throw new Error('No container runtime found. Install Apple Container, Docker, or Podman.');
}

const engine = runtime();
if (command === 'list') {
  const result = spawnSync(engine, ['images', '--filter', 'reference=ghcr.io/xynolog/xynolog-*'], { stdio: 'inherit' });
  process.exit(result.status ?? 1);
}
if (command === 'clean') {
  for (const name of names) {
    const tag = `ghcr.io/xynolog/xynolog-${name}:local`;
    const result = spawnSync(engine, ['image', 'rm', tag], { stdio: 'ignore' });
    if (!result.error && result.status === 0) console.log(`Removed ${tag}`);
  }
  process.exit(0);
}
console.error('Usage: node scripts/container-utils.js [list|clean]');
process.exit(2);
