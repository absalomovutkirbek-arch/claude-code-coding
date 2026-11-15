/**
 * PostToolUse hook for Edit|Write|MultiEdit.
 *
 * Checks the TypeScript code Claude just wrote against the layer and type rules
 * (.claude/rules/react/structure.md, data-layer.md, ui-layer.md).
 *
 * Only the newly written text is checked, so untouched legacy code never triggers it.
 * Test files and src/test/ are skipped.
 * Exit 2 sends the findings on stderr back to Claude so it can fix them. The edit itself is not undone.
 */

import { readFileSync } from 'node:fs';
import { basename } from 'node:path';

let input;
try {
  input = JSON.parse(readFileSync(0, 'utf8'));
} catch {
  process.exit(0);
}

const toolInput = input?.tool_input ?? {};
const path = toolInput.file_path;
if (typeof path !== 'string' || !/\.(ts|tsx)$/.test(path) || /\.d\.ts$/.test(path)) {
  process.exit(0);
}

const normalized = path.replaceAll('\\', '/');
const srcIndex = normalized.lastIndexOf('/src/');
if (srcIndex === -1) {
  process.exit(0);
}
const relative = normalized.slice(srcIndex + 1); // "src/..."
if (/\.test\.tsx?$/.test(relative) || relative.startsWith('src/test/') || /\/test\//.test(relative)) {
  process.exit(0);
}

const written = [];
if (typeof toolInput.content === 'string') written.push(toolInput.content);
if (typeof toolInput.new_string === 'string') written.push(toolInput.new_string);
for (const edit of toolInput.edits ?? []) {
  if (typeof edit?.new_string === 'string') written.push(edit.new_string);
}

// Drop comment lines so that documentation mentioning a forbidden construct is not flagged.
const code = written
  .join('\n')
  .split('\n')
  .filter((line) => !/^\s*(\/\/|\/\*|\*)/.test(line))
  .join('\n');
if (code.trim() === '') {
  process.exit(0);
}

const featureMatch = /^src\/features\/([^/]+)\//.exec(relative);
const feature = featureMatch?.[1] ?? null;
const inShared = relative.startsWith('src/shared/');
const isHttpModule = relative === 'src/shared/api/http.ts';
const inApiModule = /\/api\/[^/]+\.api\.ts$/.test(relative);
const inPagesOrComponents = /\/(pages|components)\//.test(relative) || relative.startsWith('src/shared/ui/');

const problems = [];

function check(pattern, message) {
  const match = pattern.exec(code);
  if (match !== null) {
    problems.push(`${message} (\`${match[0].trim()}\`)`);
  }
}

// TypeScript
check(/(:\s*any\b|\bas\s+any\b|<any>|\bany\[\])/, 'No `any`: type the value, or use `unknown` and narrow it');
check(/@ts-(ignore|nocheck|expect-error)/, 'Do not silence the compiler; fix the type');
check(/^\s*(export\s+)?(const\s+)?enum\s+\w+/m, 'No `enum`: use an `as const` object and a derived union type');
check(/^\s*export\s+default\b/m, 'Use named exports');

// Clean code and security
check(/\bconsole\.(log|debug|info)\s*\(/, 'Remove debug output');
check(/dangerouslySetInnerHTML/, 'Do not render raw HTML');
check(/localStorage\.setItem\s*\(\s*['"`][^'"`]*token/i, 'Tokens are kept only by shared/auth/tokenStore.ts, never in localStorage');

// Network access
if (!isHttpModule) {
  check(/from\s+['"]axios['"]/, '`axios` is imported only in shared/api/http.ts');
  check(/(^|[^.\w])fetch\s*\(/m, 'Do not call fetch; add a function to the feature\'s api/*.api.ts that uses `http`');
}
if (!inApiModule && !isHttpModule && !inShared) {
  check(/from\s+['"](@\/shared\/api\/http|[./]+(shared\/api\/)?http)['"]/, 'Only features/<feature>/api/*.api.ts calls `http`');
}

// Layers
if (inPagesOrComponents) {
  check(/\b(useQuery|useMutation|useInfiniteQuery|useSuspenseQuery)\s*[(<]/, 'Pages and components use the feature\'s hooks, not TanStack Query directly');
  check(/from\s+['"][./]+api\/[^'"]+['"]/, 'Pages and components call the feature\'s hooks, not its API module');
  check(/useEffect\s*\(\s*\(\)\s*=>\s*\{[^}]*\b(get|list|load|fetch)\w*\s*\(/s, 'Do not load data in useEffect; use a query hook');
}

// Imports between features and from shared
for (const match of code.matchAll(/from\s+['"]@\/features\/([^/'"]+)(\/[^'"]*)?['"]/g)) {
  const [statement, target, deepPath] = match;
  if (inShared) {
    problems.push(`shared/ must not import from features/ (\`${statement}\`)`);
  } else if (deepPath !== undefined && target !== feature) {
    problems.push(`Import another feature only through its index.ts: \`@/features/${target}\` (\`${statement}\`)`);
  }
}

if (problems.length === 0) {
  process.exit(0);
}

process.stderr.write(
  `${basename(path)}:\n- ${problems.join('\n- ')}\n` +
    'Fix these now. If a finding is a false positive, say why in your summary and continue.\n',
);
process.exit(2);
