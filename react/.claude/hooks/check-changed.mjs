/**
 * Runs the layer check (check-ts.mjs) on every TypeScript file changed since a git ref.
 *
 *   node .claude/hooks/check-changed.mjs              # uncommitted changes (against HEAD)
 *   node .claude/hooks/check-changed.mjs origin/main  # everything on this branch
 *
 * For sessions where Claude Code does not run the hooks from .claude/settings.json
 * (for example cloud threads of a claude.ai project), and for CI.
 * Modified files are checked on their added lines only, new files as a whole.
 * Exit 1 when a file has findings.
 */

import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const hooksDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(hooksDir, '..', '..');
const base = process.argv[2] ?? 'HEAD';

function git(args) {
  try {
    return execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })
      .split('\n')
      .filter((line) => line !== '');
  } catch {
    return [];
  }
}

const modified = git(['diff', '--name-only', '--diff-filter=M', base]);
const added = [
  ...new Set([
    ...git(['diff', '--name-only', '--diff-filter=A', base]),
    ...git(['ls-files', '--others', '--exclude-standard']),
  ]),
];

let checked = 0;
let failed = 0;

function run(file, toolInput) {
  const path = join(root, file);
  if (!/\.tsx?$/.test(file) || !existsSync(path)) {
    return;
  }

  checked += 1;
  const result = spawnSync(process.execPath, [join(hooksDir, 'check-ts.mjs')], {
    cwd: root,
    input: JSON.stringify({ tool_input: { file_path: path, ...toolInput } }),
    stdio: ['pipe', 'inherit', 'inherit'],
  });
  if (result.status !== 0) {
    failed += 1;
  }
}

for (const file of added) {
  const path = join(root, file);
  run(file, { content: existsSync(path) ? readFileSync(path, 'utf8') : '' });
}

for (const file of modified) {
  const addedLines = git(['diff', '-U0', base, '--', file])
    .filter((line) => line.startsWith('+') && !line.startsWith('+++'))
    .map((line) => line.slice(1));
  run(file, { new_string: addedLines.join('\n') });
}

console.error(`check-changed: ${checked} TypeScript file(s) checked against ${base}, ${failed} with findings.`);
process.exit(failed > 0 ? 1 : 0);
