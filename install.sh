#!/usr/bin/env bash
#
# Installs a stack setup into a project.
#
#   ./install.sh <stack> <path-to-project> [--force]
#
#   ./install.sh yii2 ~/projects/my-api
#
# Copies:
#   common/rules/*           -> <project>/.claude/rules/common/
#   <stack>/.claude/*        -> <project>/.claude/
#   <stack>/CLAUDE.md        -> <project>/CLAUDE.md
#
# Existing CLAUDE.md and .claude/settings.json are never overwritten unless --force is given:
# the new versions are written next to them as *.new for manual merging.

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 <stack> <path-to-project> [--force]"
    echo "Stacks:"
    for dir in "$SOURCE_DIR"/*/; do
        name="$(basename "$dir")"
        if [[ -f "$dir/CLAUDE.md" ]]; then
            echo "  $name"
        fi
    done
    exit 1
}

[[ $# -ge 2 ]] || usage

STACK="$1"
TARGET="$2"
FORCE="${3:-}"

STACK_DIR="$SOURCE_DIR/$STACK"
[[ -f "$STACK_DIR/CLAUDE.md" ]] || { echo "Unknown stack: $STACK"; usage; }
[[ -d "$TARGET" ]] || { echo "Project directory not found: $TARGET"; exit 1; }

TARGET="$(cd "$TARGET" && pwd)"

# Copies a file, keeping an existing target unless --force is given.
copy_protected() {
    local source="$1" target="$2"

    if [[ -f "$target" && "$FORCE" != "--force" ]]; then
        if cmp -s "$source" "$target"; then
            echo "  unchanged  ${target#"$TARGET"/}"
        else
            cp "$source" "$target.new"
            echo "  EXISTS     ${target#"$TARGET"/} kept; new version written to ${target#"$TARGET"/}.new - merge it by hand"
        fi
    else
        cp "$source" "$target"
        echo "  installed  ${target#"$TARGET"/}"
    fi
}

echo "Installing '$STACK' setup into $TARGET"

mkdir -p "$TARGET/.claude/rules/common"

# 1. Shared rules: owned by this repository, always refreshed.
cp "$SOURCE_DIR"/common/rules/*.md "$TARGET/.claude/rules/common/"
echo "  installed  .claude/rules/common/ ($(ls "$SOURCE_DIR"/common/rules/*.md | wc -l | tr -d ' ') files)"

# 2. Stack rules, skills and hooks: owned by this repository, always refreshed.
for part in rules skills hooks; do
    if [[ -d "$STACK_DIR/.claude/$part" ]]; then
        mkdir -p "$TARGET/.claude/$part"
        cp -R "$STACK_DIR/.claude/$part/." "$TARGET/.claude/$part/"
        echo "  installed  .claude/$part/"
    fi
done

# 3. Files the project is expected to customise: never overwritten silently.
if [[ -f "$STACK_DIR/.claude/settings.json" ]]; then
    copy_protected "$STACK_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
fi
copy_protected "$STACK_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"

echo
echo "Done. Next steps:"
echo "  1. cd $TARGET && claude"
echo "  2. Run /adopt-project so Claude fills 'Project facts' in CLAUDE.md"
echo "  3. Commit CLAUDE.md and .claude/ to the project repository"
