#!/usr/bin/env bash
#
# Runs the layer check (check-java.sh) on every Java file changed since a git ref.
#
#   bash .claude/hooks/check-changed.sh              # uncommitted changes (against HEAD)
#   bash .claude/hooks/check-changed.sh origin/main  # everything on this branch
#
# For sessions where Claude Code does not run the hooks from .claude/settings.json
# (for example cloud threads of a claude.ai project), and for CI.
# Modified files are checked on their added lines only, new files as a whole.
# Exit 1 when a file has findings.

hooks_dir="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$hooks_dir/../.." && pwd)"
base="${1:-HEAD}"

cd "$root" || exit 0

checked=0
failed=0

while IFS= read -r file; do
    case "$file" in
        *.java) ;;
        *) continue ;;
    esac
    [ -f "$root/$file" ] || continue

    checked=$((checked + 1))
    if ! printf '{"tool_input":{"file_path":"%s"}}' "$root/$file" | HOOK_DIFF_BASE="$base" bash "$hooks_dir/check-java.sh"; then
        failed=$((failed + 1))
    fi
done < <(
    {
        git diff --name-only --diff-filter=AM "$base" 2>/dev/null
        git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u
)

echo "check-changed: $checked Java file(s) checked against $base, $failed with findings." >&2
[ "$failed" -eq 0 ]
