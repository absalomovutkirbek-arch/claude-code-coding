#!/usr/bin/env bash
# Shared helpers for the hooks. Sourced, not executed.

# Prints tool_input.file_path from the hook JSON on stdin, with forward slashes.
hook_file_path() {
    local input path
    input=$(cat)

    if command -v jq >/dev/null 2>&1; then
        path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    elif command -v python3 >/dev/null 2>&1; then
        path=$(printf '%s' "$input" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))
except Exception:
    pass' 2>/dev/null)
    else
        # Last resort without a JSON parser: the first "file_path" key of the payload.
        path=$(printf '%s' "$input" | sed -n 's/^[^\\]*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
        path=${path//\\\\/\/}
    fi

    printf '%s' "${path//\\//}"
}

# True when the file is tracked by git (committed or staged).
is_tracked() {
    git -C "$(dirname "$1")" ls-files --error-unmatch -- "$(basename "$1")" >/dev/null 2>&1
}
