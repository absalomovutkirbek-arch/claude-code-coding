<?php

/**
 * PostToolUse hook for Edit|Write|MultiEdit.
 *
 * 1. Runs `php -l` on the edited PHP file.
 * 2. Checks the code Claude just wrote against the layer rules
 *    (.claude/rules/common/architecture.md, .claude/rules/yii2/structure.md).
 *
 * Only the newly written text is checked, so untouched legacy code never triggers it.
 * Exit 2 sends the findings on stderr back to Claude so it can fix them. The edit itself is not undone.
 */

declare(strict_types=1);

$input = json_decode((string) stream_get_contents(STDIN), true);
if (!is_array($input)) {
    exit(0);
}

$toolInput = $input['tool_input'] ?? [];
$path = $toolInput['file_path'] ?? null;

if (!is_string($path) || !str_ends_with($path, '.php') || !is_file($path)) {
    exit(0);
}

$normalized = str_replace('\\', '/', $path);
$problems = [];

// 1. Syntax -----------------------------------------------------------------

exec(sprintf('%s -l %s 2>&1', escapeshellarg(PHP_BINARY), escapeshellarg($path)), $lintOutput, $lintStatus);
if ($lintStatus !== 0) {
    $problems[] = "Syntax error:\n  " . implode("\n  ", array_filter($lintOutput));
}

// 2. Layer rules on the new code -------------------------------------------

$written = [];
if (isset($toolInput['content']) && is_string($toolInput['content'])) {
    $written[] = $toolInput['content'];
}
if (isset($toolInput['new_string']) && is_string($toolInput['new_string'])) {
    $written[] = $toolInput['new_string'];
}
foreach ($toolInput['edits'] ?? [] as $edit) {
    if (is_array($edit) && isset($edit['new_string']) && is_string($edit['new_string'])) {
        $written[] = $edit['new_string'];
    }
}

// Drop comment lines so that documentation mentioning a forbidden call is not flagged.
$code = implode("\n", array_filter(
    explode("\n", implode("\n", $written)),
    static fn (string $line): bool => preg_match('#^\s*(//|\#|/\*|\*)#', $line) !== 1,
));

$queries = [
    '/::find(One|All|BySql)?\s*\(/' => 'ActiveRecord query',
    '/new\s+\\\\?(yii\\\\db\\\\)?Query\s*\(/' => 'Query builder',
    '/->createCommand\s*\(/' => 'raw SQL command',
];
$writes = [
    // Only unambiguous ActiveRecord calls: `->update(` and `->delete(` are also valid service method names.
    '/(->|::)(save|updateAttributes|updateAll|updateCounters|deleteAll)\s*\(/' => 'ActiveRecord write',
];
$transactions = [
    '/->beginTransaction\s*\(/' => 'manual transaction',
    '/Yii::\$app->db\b/' => 'direct database connection',
];
$httpState = [
    '/Yii::\$app->(request|response|session|user)\b/' => 'HTTP state (request/response/session/user)',
];
$anyYiiApp = [
    '/Yii::\$app\b/' => 'Yii::$app service locator',
];

$layers = [
    'controllers' => [
        'rules' => $queries + $writes + $transactions,
        'hint' => 'A controller only maps action IDs to Action classes. Move the logic to a service and the queries to a repository.',
    ],
    'actions' => [
        'rules' => $queries + $writes + $transactions,
        'hint' => 'An action only validates, calls one service method and returns a resource. Move the logic to a service and the queries to a repository.',
    ],
    'forms' => [
        'rules' => $writes + $transactions,
        'hint' => 'A form only validates input and builds a DTO.',
    ],
    'services' => [
        'rules' => $queries + $transactions + $anyYiiApp,
        'hint' => 'A service gets data through repository interfaces, transactions through TransactionManagerInterface and the current user through the DTO. Inject dependencies through the constructor.',
    ],
    'strategies' => [
        'rules' => $queries + $transactions + $anyYiiApp,
        'hint' => 'A strategy receives its dependencies through the constructor and works through repositories or gateways.',
    ],
    'repositories' => [
        'rules' => ['/->beginTransaction\s*\(/' => 'manual transaction', '/->transaction\s*\(/' => 'transaction'] + $httpState,
        'hint' => 'A repository only reads and writes. The transaction boundary belongs to the service.',
    ],
    'models' => [
        'rules' => $httpState + $transactions,
        'hint' => 'A model only maps a table. Move the logic to a service.',
    ],
    'dto' => [
        'rules' => $anyYiiApp + $queries + $writes,
        'hint' => 'A DTO only carries data.',
    ],
    'resources' => [
        'rules' => $queries + $writes + $anyYiiApp,
        'hint' => 'A resource only shapes output from data the service already loaded.',
    ],
];

foreach ($layers as $folder => $layer) {
    if (preg_match("#(^|/){$folder}/#", $normalized) !== 1) {
        continue;
    }

    $found = [];
    foreach ($layer['rules'] as $pattern => $label) {
        if (preg_match($pattern, $code, $match) === 1) {
            $found[] = "{$label} (`" . trim($match[0]) . '`)';
        }
    }

    if ($found !== []) {
        $problems[] = "Layer rule broken in {$folder}/: " . implode(', ', $found) . ".\n  " . $layer['hint'];
    }

    break;
}

$isApplicationCode = preg_match('#(^|/)(modules|core)/#', $normalized) === 1;
$isWholeFile = isset($toolInput['content']);
if ($isApplicationCode && $isWholeFile && !str_contains((string) $toolInput['content'], 'declare(strict_types=1);')) {
    $problems[] = 'Missing `declare(strict_types=1);` at the top of the file.';
}

if ($problems === []) {
    exit(0);
}

fwrite(STDERR, basename($path) . ":\n- " . implode("\n- ", $problems) . "\n"
    . "Fix these now. If a finding is a false positive, say why in your summary and continue.\n");
exit(2);
