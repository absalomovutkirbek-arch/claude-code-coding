#!/usr/bin/env bash
#
# PreToolUse hook for Edit|Write|MultiEdit.
#
# Blocks edits to files Claude must never change:
#   - .env files (secrets)
#   - build output (target/, build/)
#   - Flyway migrations that are already committed to git (applied migrations are immutable;
#     Flyway's checksum validation would stop the application)
#
# Exit 2 blocks the tool call and shows the message on stderr to Claude.
# Any other outcome lets the call through.

. "$(dirname "$0")/lib.sh"

path=$(hook_file_path)
[ -z "$path" ] && exit 0

name=$(basename "$path")

block() {
    echo "BLOCKED: $1" >&2
    exit 2
}

case "$name" in
    .env.example | .env.dist | .env.sample) ;;
    .env | .env.*)
        block "$name holds secrets and must not be edited by Claude. Ask the developer to change it, or edit .env.example."
        ;;
esac

case "/$path" in
    */target/* | */build/classes/* | */build/libs/* | */build/generated/*)
        block "This is build output. Change the source file instead."
        ;;
esac

case "$path" in
    */db/migration/*.sql | */db/migration/*.java)
        if [ -f "$path" ] && is_tracked "$path"; then
            block "$name is a committed migration. Applied migrations are immutable. Create a new migration with /new-migration instead."
        fi
        ;;
esac

exit 0
