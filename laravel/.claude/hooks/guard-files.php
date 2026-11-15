<?php

/**
 * PreToolUse hook for Edit|Write|MultiEdit.
 *
 * Blocks edits to files Claude must never change:
 *   - .env files (secrets)
 *   - vendor/ (third-party code)
 *   - migrations that are already committed to git (applied migrations are immutable)
 *
 * Exit 2 blocks the tool call and shows the message on stderr to Claude.
 * Any other outcome lets the call through.
 */

declare(strict_types=1);

$input = json_decode((string) stream_get_contents(STDIN), true);
$path = is_array($input) ? ($input['tool_input']['file_path'] ?? null) : null;

if (!is_string($path) || $path === '') {
    exit(0);
}

$normalized = str_replace('\\', '/', $path);
$name = basename($normalized);

/** @return never */
function block(string $message): void
{
    fwrite(STDERR, "BLOCKED: {$message}\n");
    exit(2);
}

if (preg_match('/^\.env(\..+)?$/', $name) === 1 && !preg_match('/\.(example|dist|sample)$/', $name)) {
    block("{$name} holds secrets and must not be edited by Claude. Ask the developer to change it, or edit .env.example.");
}

if (preg_match('#(^|/)vendor/#', $normalized) === 1) {
    block('vendor/ is third-party code. Change behaviour through configuration, a decorator or an adapter in the project.');
}

if (preg_match('#(^|/)migrations/[^/]+\.php$#i', $normalized) === 1 && is_file($path)) {
    $directory = dirname($path);
    $command = sprintf(
        'git -C %s ls-files --error-unmatch -- %s 2>%s',
        escapeshellarg($directory),
        escapeshellarg($name),
        DIRECTORY_SEPARATOR === '\\' ? 'NUL' : '/dev/null',
    );
    exec($command, $output, $status);

    if ($status === 0) {
        block(
            "{$name} is a committed migration. Applied migrations are immutable. "
            . 'Create a new migration with /new-migration instead.',
        );
    }
}

exit(0);
