<?php

/**
 * Runs the layer check (check-php.php) on every PHP file changed since a git ref.
 *
 *   php .claude/hooks/check-changed.php            # uncommitted changes (against HEAD)
 *   php .claude/hooks/check-changed.php origin/main  # everything on this branch
 *
 * For sessions where Claude Code does not run the hooks from .claude/settings.json
 * (for example cloud threads of a claude.ai project), and for CI.
 * Modified files are checked on their added lines only, new files as a whole.
 * Exit 1 when a file has findings.
 */

declare(strict_types=1);

$root = dirname(__DIR__, 2);
chdir($root);

$base = $argv[1] ?? 'HEAD';

/** @return list<string> */
$git = static function (string $arguments): array {
    exec('git ' . $arguments . ' 2>/dev/null', $lines, $status);

    return $status === 0 ? array_values(array_filter($lines, static fn (string $line): bool => $line !== '')) : [];
};

$baseArgument = escapeshellarg($base);
$modified = $git('diff --name-only --diff-filter=M ' . $baseArgument);
$added = array_merge(
    $git('diff --name-only --diff-filter=A ' . $baseArgument),
    $git('ls-files --others --exclude-standard'),
);

$checked = 0;
$failed = 0;

$run = static function (string $file, array $toolInput) use ($root, &$checked, &$failed): void {
    if (!str_ends_with($file, '.php') || !is_file($root . '/' . $file)) {
        return;
    }

    $checked++;
    $process = proc_open(
        [PHP_BINARY, __DIR__ . '/check-php.php'],
        [0 => ['pipe', 'r'], 1 => STDOUT, 2 => STDERR],
        $pipes,
        $root,
    );
    if (!is_resource($process)) {
        return;
    }

    fwrite($pipes[0], (string) json_encode(['tool_input' => ['file_path' => $root . '/' . $file] + $toolInput]));
    fclose($pipes[0]);

    if (proc_close($process) !== 0) {
        $failed++;
    }
};

foreach (array_unique($added) as $file) {
    $run($file, ['content' => (string) @file_get_contents($root . '/' . $file)]);
}

foreach ($modified as $file) {
    $addedLines = [];
    foreach ($git('diff -U0 ' . $baseArgument . ' -- ' . escapeshellarg($file)) as $line) {
        if (str_starts_with($line, '+') && !str_starts_with($line, '+++')) {
            $addedLines[] = substr($line, 1);
        }
    }
    $run($file, ['new_string' => implode("\n", $addedLines)]);
}

fwrite(STDERR, sprintf("check-changed: %d PHP file(s) checked against %s, %d with findings.\n", $checked, $base, $failed));
exit($failed > 0 ? 1 : 0);
