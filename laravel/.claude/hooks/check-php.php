<?php

/**
 * PostToolUse hook for Edit|Write|MultiEdit.
 *
 * 1. Runs `php -l` on the edited PHP file.
 * 2. Checks the code Claude just wrote against the layer rules
 *    (.claude/rules/common/architecture.md, .claude/rules/laravel/structure.md).
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

// Static calls that are Eloquent queries when made on a model class.
const ELOQUENT_STATIC = 'query|where\w*|find|findOrFail|findMany|first|firstOrFail|firstWhere|firstOrCreate|firstOrNew'
    . '|updateOrCreate|upsert|create|insert|destroy|all|with|select|orderBy|latest|paginate|count|exists';

// Classes whose static methods share those names but are not models.
const NOT_MODELS = ['Arr', 'Str', 'Collection', 'Carbon', 'CarbonImmutable', 'Rule', 'Route', 'Schema', 'Validator',
    'File', 'Storage', 'Cache', 'Config', 'Log', 'Http', 'Gate', 'Lang', 'self', 'static', 'parent'];

$eloquentStatic = static function (string $code): ?string {
    preg_match_all('/\b([A-Z]\w*|self|static)::(' . ELOQUENT_STATIC . ')\s*\(/', $code, $matches, PREG_SET_ORDER);
    foreach ($matches as $match) {
        if (!in_array($match[1], NOT_MODELS, true)) {
            return 'Eloquent query (`' . $match[1] . '::' . $match[2] . '(`)';
        }
    }

    return null;
};

$dbFacade = ['/\bDB::\w+/' => 'DB facade'];
$writes = [
    // `->save($model)` and `->delete($id)` are repository/service calls; without arguments they are Eloquent writes.
    '/->(save|delete|push|touch)\s*\(\s*\)/' => 'Eloquent write',
    '/->(update|fill|forceFill)\s*\(\s*\[/' => 'Eloquent mass update',
    '/->(saveOrFail|saveQuietly|deleteOrFail|deleteQuietly|forceDelete|updateOrFail|updateQuietly)\s*\(/' => 'Eloquent write',
];
$transactions = [
    '/\bDB::(transaction|beginTransaction|commit|rollBack)\b/' => 'manual transaction',
    '/->(beginTransaction|transaction)\s*\(/' => 'manual transaction',
];
$httpState = [
    '/(?<![\w>:$])(?<!function )(request|auth|session)\s*\(/' => 'HTTP state helper',
    '/\b(Auth|Request|Session)::\w+/' => 'HTTP state facade',
];
$container = [
    '/(?<![\w>:$])(?<!function )(app|resolve|event|dispatch)\s*\(/' => 'container/helper call',
    '/\bEvent::\w+/' => 'Event facade',
];
$massAssignment = [
    '/\$request->(all|validated|input|post|except|only)\s*\(\s*\)/' => 'raw request data',
];

$layers = [
    'Http/Controllers' => [
        'eloquent' => true,
        'rules' => $dbFacade + $writes + $transactions,
        'hint' => 'New endpoints are invokable Action classes in Http/Actions. HTTP classes only call one service method; move the logic to a service and the queries to a repository.',
    ],
    'Http/Actions' => [
        'eloquent' => true,
        'rules' => $dbFacade + $writes + $transactions + $massAssignment,
        'hint' => 'An action only receives a FormRequest, calls one service method and returns ApiResponse with a resource. Move the logic to a service and the queries to a repository; build input with $request->toDto().',
    ],
    'Http/Requests' => [
        'eloquent' => true,
        'rules' => $dbFacade + $writes + $transactions,
        'hint' => 'A form request only validates input format and builds a DTO. Use exists/unique rules for reference checks.',
    ],
    'Http/Resources' => [
        'eloquent' => true,
        'rules' => $dbFacade + $writes,
        'hint' => 'A resource only shapes output from data the service already loaded. Use whenLoaded() for relations.',
    ],
    'Services' => [
        'eloquent' => true,
        'rules' => $dbFacade + $writes + $transactions + $httpState + $container,
        'hint' => 'A service gets data through repository interfaces, transactions through TransactionManagerInterface, events through the injected Dispatcher and the current user through the DTO. Inject dependencies through the constructor.',
    ],
    'Strategies' => [
        'eloquent' => true,
        'rules' => $dbFacade + $writes + $transactions + $httpState + $container,
        'hint' => 'A strategy receives its dependencies through the constructor and works through repositories or gateways.',
    ],
    'Repositories' => [
        'eloquent' => false,
        'rules' => $transactions + $httpState,
        'hint' => 'A repository only reads and writes. The transaction boundary belongs to the service and the current user arrives as a parameter.',
    ],
    'Models' => [
        'eloquent' => false,
        'rules' => $dbFacade + $transactions + $httpState + $container,
        'hint' => 'A model only maps a table. Move queries to the repository and logic to a service.',
    ],
    'Dto' => [
        'eloquent' => true,
        'rules' => $dbFacade + $writes + $httpState + $container,
        'hint' => 'A DTO only carries data.',
    ],
];

foreach ($layers as $folder => $layer) {
    if (!str_contains($normalized, '/' . $folder . '/')) {
        continue;
    }

    $found = [];
    if ($layer['eloquent'] && ($query = $eloquentStatic($code)) !== null) {
        $found[] = $query;
    }
    foreach ($layer['rules'] as $pattern => $label) {
        if (preg_match($pattern, $code, $match) === 1) {
            $found[] = "{$label} (`" . trim($match[0]) . '`)';
        }
    }

    if ($found !== []) {
        $problems[] = "Layer rule broken in {$folder}/: " . implode(', ', array_unique($found)) . ".\n  " . $layer['hint'];
    }

    break;
}

$isApplicationCode = preg_match('#(^|/)app/(Modules|Core)/#', $normalized) === 1;
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
