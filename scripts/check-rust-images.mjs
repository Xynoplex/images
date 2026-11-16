#!/usr/bin/env node
/**
 * lint:rust-images — the Rust service images share their build stages.
 *
 * A Rust service's image is the <service>/Dockerfile with a `FROM rust:`
 * stage. Its build stages run from that line to its last stage, the runtime
 * stage, which is where the image states its facts (its port, health route,
 * user, environment and command). Every one carries the same build stages,
 * which build every service's binary. An image built after, or beside,
 * another then reuses them instead of compiling the workspace again.
 *
 * 1. The build stages, from `FROM rust:` to the last FROM, are the same text.
 * 2. They build (`-p`) and keep (`cp target/release/`) exactly the binaries
 *    the images copy out of them (`COPY --from=builder /<binary>`).
 * 3. They copy every member of the workspace: its manifest, its `src` and its
 *    build script when it has one. Cargo loads every member to build any one,
 *    so a member they leave out fails every image's build.
 */
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, posix } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
/** The workspace's root, which names its members. */
const WORKSPACE = 'packages/rust';
const failures = [];
const fail = (message) => failures.push(message);

/** Each Rust service's Dockerfile: its build stages, and the binaries it copies from them. */
const images = readdirSync(ROOT)
  .map((app) => `${app}/Dockerfile`)
  .filter((path) => existsSync(join(ROOT, path)))
  .map((path) => ({ path, lines: readFileSync(join(ROOT, path), 'utf8').split('\n') }))
  .filter(({ lines }) => lines.some((l) => /^FROM rust:/.test(l)))
  .map(({ path, lines }) => {
    const start = lines.findIndex((l) => /^FROM rust:/.test(l));
    const end = lines.findLastIndex((l) => /^FROM /.test(l));
    if (end <= start) fail(`${path}: its build stages are not followed by a runtime stage`);
    const copied = lines.flatMap((l) => [...l.matchAll(/^COPY --from=builder \/([a-z][a-z0-9-]*) /g)].map((m) => m[1]));
    return { path, builder: lines.slice(start, end <= start ? lines.length : end).join('\n'), copied };
  });

if (images.length === 0) fail('no <service>/Dockerfile has a `FROM rust:` stage');

const [first, ...rest] = images;
for (const image of rest) {
  if (image.builder !== first.builder) fail(`${image.path}'s build stages differ from ${first.path}'s; the Rust images share them`);
}

if (first) {
  const wanted = new Set(images.flatMap((i) => i.copied));
  const built = new Set([...first.builder.matchAll(/-p ([a-z][a-z0-9-]*)/g)].map((m) => m[1]));
  const kept = new Set([...first.builder.matchAll(/target\/release\/([a-z][a-z0-9-]*)/g)].map((m) => m[1]));
  for (const binary of wanted) {
    if (!built.has(binary)) fail(`an image copies ${binary} from the builder, and the build stages do not build it (-p ${binary})`);
    if (!kept.has(binary)) fail(`an image copies ${binary} from the builder, and the build stages do not keep it (cp target/release/${binary})`);
  }
  for (const binary of new Set([...built, ...kept])) {
    if (!wanted.has(binary)) fail(`the build stages build ${binary}, and no image copies it`);
  }
}

if (first) {
  const workspace = readFileSync(join(ROOT, WORKSPACE, 'Cargo.toml'), 'utf8');
  // A member is named from the workspace's root; the build stages copy it from the repository's.
  const members = [...(workspace.match(/^members = \[([^\]]*)\]/m)?.[1] ?? '').matchAll(/"([^"]+)"/g)].map((m) => posix.normalize(posix.join(WORKSPACE, m[1])));
  if (members.length === 0) fail(`${WORKSPACE}/Cargo.toml names no workspace members: the check has lost what it reads`);
  const copies = (source) => new RegExp(`^COPY (?:\\S+ )*${source.replaceAll('/', '\\/')} `, 'm').test(first.builder);
  for (const member of members) {
    if (!copies(`${member}/Cargo.toml`)) fail(`the build stages do not copy ${member}/Cargo.toml, a member of the workspace`);
    if (!copies(`${member}/src`)) fail(`the build stages do not copy ${member}/src, a member of the workspace`);
    if (existsSync(join(ROOT, member, 'build.rs')) && !copies(`${member}/build.rs`)) fail(`the build stages do not copy ${member}/build.rs`);
  }
}

if (failures.length > 0) {
  console.error(`❌ lint:rust-images — ${failures.length} problem(s):`);
  for (const f of failures) console.error(`   ${f}`);
  process.exit(1);
}
console.log(`✅ lint:rust-images — ${images.map((i) => i.path).join(' and ')} share their build stages, which build ${[...new Set(images.flatMap((i) => i.copied))].join(' and ')}`);
