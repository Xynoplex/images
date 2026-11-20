/**
 * The files git tracks in the repository at `root`, as repository-relative
 * paths. A submodule is one entry, its path; the files inside it are its own
 * repository's.
 */
import { execFileSync } from 'node:child_process';

export function repositoryFiles(root) {
  return execFileSync('git', ['ls-files', '-z'], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })
    .split('\0')
    .filter(Boolean);
}
