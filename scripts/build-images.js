#!/usr/bin/env node

const { spawnSync } = require('node:child_process');
const path = require('node:path');

const script = path.join(__dirname, 'build-session.sh');
const result = spawnSync(script, process.argv.slice(2), { stdio: 'inherit' });
if (result.error) throw result.error;
process.exit(result.status ?? 1);
