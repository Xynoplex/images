#!/usr/bin/env node
/**
 * Every service image's NOTICE credits exactly the third-party components its
 * runtime stage ships — no fewer, no more.
 *
 * A NOTICE's component list restates, by hand, what the Dockerfile puts in the
 * image, and nothing kept the two in step. Both directions had drifted:
 * `tini` was installed by all eight service images and credited by none, and
 * the gateway's NOTICE kept crediting Git after the image stopped installing
 * it. Attribution that omits a shipped component is a licence obligation
 * unmet; attribution of one that is absent misdescribes the image.
 *
 * What an image ships is read from its Dockerfile's LAST stage — earlier
 * stages build and are discarded:
 *
 *   - the base image: `FROM node:<tag>-alpine` ships Node.js and Alpine Linux;
 *   - every package named by `apk add`;
 *   - every binary copied out of another image, `COPY --from=<registry/image:tag>`
 *     (a `--from` naming a build stage is not a component).
 *
 * What a NOTICE credits is its two-space-indented `<name> - <licence>` lines.
 * Names match on their first word, case-insensitively, with a `.js` suffix
 * dropped: `Node.js` is `node`, `Typst (typesetting compiler, …)` is `typst`.
 *
 * A Python image's NOTICE also lists, under "Python packages built into the
 * image from this repository:", the packages its uv.lock takes from anywhere
 * but a registry: the SDK's wheel and this repository's own packages. The
 * names on that list's four-space-indented lines are exactly those. Other
 * four-space-indented lines (npm packages, bundled libraries, font notices)
 * differ in shape per image and are not checked.
 */
import { existsSync, readdirSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const IMAGES = ROOT;

const key = (name) => name.trim().toLowerCase().split(/[\s(]/)[0].replace(/\.js$/, '');

function shipped(dockerfile) {
  const source = dockerfile.replace(/\\\r?\n/g, ' ');
  const stages = source.split(/^FROM\s+/m).slice(1);
  const last = stages[stages.length - 1];
  if (!last) return null;
  const out = new Set();

  const [image] = last.split(/\s/);
  const [repo, tag = ''] = image.split(':');
  out.add(key(repo.split('/').pop()));
  if (tag.includes('alpine')) out.add('alpine');

  for (const [, args] of last.matchAll(/\bapk\s+add\b([^&;\n]*)/g)) {
    const tokens = args.trim().split(/\s+/).filter(Boolean);
    for (let i = 0; i < tokens.length; i++) {
      if (tokens[i] === '--virtual' || tokens[i] === '-t') { i++; continue; }
      if (!tokens[i].startsWith('-')) out.add(key(tokens[i].split('=')[0]));
    }
  }

  for (const [, ref] of last.matchAll(/\bCOPY\s+--from=(\S+)/g)) {
    if (!ref.includes('/') && !ref.includes(':')) continue;
    out.add(key(ref.split(':')[0].split('/').pop()));
  }
  return out;
}

function credited(notice) {
  const out = new Set();
  for (const [, name] of notice.matchAll(/^ {2}(\S[^\n]*?) - [^\n]*License/gm)) out.add(key(name));
  return out;
}

const BUILT_HERE = '  Python packages built into the image from this repository:';

function locallyBuilt(lock) {
  const out = new Set();
  for (const entry of lock.split(/^\[\[package\]\]$/m).slice(1)) {
    const name = entry.match(/^name = "([^"]+)"$/m)[1];
    const source = entry.match(/^source = \{ (\w+) = /m)[1];
    if (source !== 'registry') out.add(name);
  }
  return out;
}

function listedAsBuiltHere(notice) {
  const lines = notice.split('\n');
  const start = lines.indexOf(BUILT_HERE);
  if (start === -1) return null;
  const out = new Set();
  for (const line of lines.slice(start + 1)) {
    if (!line.startsWith('    ')) break;
    out.add(line.trim().split(/\s/)[0]);
  }
  return out;
}

const problems = [];
let checked = 0;
for (const image of readdirSync(IMAGES).sort()) {
  const dockerfile = join(IMAGES, image, 'Dockerfile');
  const notice = join(IMAGES, image, 'NOTICE');
  if (!existsSync(dockerfile) || !existsSync(notice)) continue;

  const ships = shipped(readFileSync(dockerfile, 'utf-8'));
  const credits = credited(readFileSync(notice, 'utf-8'));
  if (!ships || credits.size === 0) {
    problems.push(`${image}: could not read ${!ships ? 'a final stage from its Dockerfile' : 'any component from its NOTICE'}`);
    continue;
  }
  checked++;
  for (const c of ships) if (!credits.has(c)) problems.push(`${image}/NOTICE does not credit "${c}", which the image ships`);
  for (const c of credits) if (!ships.has(c)) problems.push(`${image}/NOTICE credits "${c}", which the image does not ship`);

  const lock = join(IMAGES, image, 'uv.lock');
  if (!existsSync(lock)) continue;
  const built = locallyBuilt(readFileSync(lock, 'utf-8'));
  const listed = listedAsBuiltHere(readFileSync(notice, 'utf-8'));
  if (!listed) {
    problems.push(`${image}/NOTICE has no "${BUILT_HERE.trim()}" list, and ${image}/uv.lock builds ${[...built].join(', ')}`);
    continue;
  }
  for (const p of built) if (!listed.has(p)) problems.push(`${image}/NOTICE does not list "${p}", which ${image}/uv.lock builds from outside a registry`);
  for (const p of listed) if (!built.has(p)) problems.push(`${image}/NOTICE lists "${p}", which ${image}/uv.lock does not build`);
}

if (checked === 0) {
  console.error('✗ lint:notice — no <service>/ has both a Dockerfile and a NOTICE. Silence is not agreement.');
  process.exit(1);
}
if (problems.length > 0) {
  console.error('✗ lint:notice — a NOTICE disagrees with what its image ships:');
  for (const p of problems) console.error(`    ${p}`);
  console.error("  Credit what the Dockerfile's last stage installs and what uv.lock builds outside a registry, and nothing else.");
  process.exit(1);
}
console.log(`✓ lint:notice — ${checked} service images credit exactly what they ship`);
