#!/usr/bin/env bash
#
# PostToolUse hook for Edit|Write|MultiEdit.
#
# Checks the Java code Claude just wrote against the layer rules
# (.claude/rules/common/architecture.md, .claude/rules/spring-boot/structure.md).
#
# Only added lines are checked (git diff against HEAD; the whole file when it is new),
# so untouched legacy code never triggers it. Test sources are skipped.
# Exit 2 sends the findings on stderr back to Claude so it can fix them. The edit itself is not undone.

. "$(dirname "$0")/lib.sh"

path=$(hook_file_path)
case "$path" in
    *.java) ;;
    *) exit 0 ;;
esac
[ -f "$path" ] || exit 0
case "$path" in
    */src/test/*) exit 0 ;;
esac

# HOOK_DIFF_BASE lets check-changed.sh compare against another ref, for example origin/main.
if is_tracked "$path"; then
    code=$(git -C "$(dirname "$path")" diff -U0 "${HOOK_DIFF_BASE:-HEAD}" -- "$(basename "$path")" 2>/dev/null | grep '^+' | grep -v '^+++' | sed 's/^+//')
else
    code=$(cat "$path")
fi

# Drop comment lines so that documentation mentioning a forbidden type is not flagged.
code=$(printf '%s\n' "$code" | grep -v -E '^[[:space:]]*(//|/\*|\*)')
[ -z "$code" ] && exit 0

problems=""

# check <label> <extended regex>: records the first match.
check() {
    local match
    match=$(printf '%s\n' "$code" | grep -o -E -m 1 -- "$2" | head -n 1)
    if [ -n "$match" ]; then
        found="${found:+$found, }$1 (\`$match\`)"
    fi
}

report() {
    if [ -n "$found" ]; then
        problems="${problems}- Layer rule broken in $1/: $found.
  $2
"
    fi
}

found=""
case "$path" in
    */controller/*)
        check "repository access" '[A-Z][A-Za-z0-9]*Repository\b'
        check "persistence API" '\b(EntityManager|JdbcTemplate|NamedParameterJdbcTemplate)\b'
        check "transaction" '@Transactional'
        check "security context" '\b(SecurityContextHolder|Principal|Authentication) '
        check "hand-built response" '\bResponseEntity\b'
        check "local exception handling" '(@ExceptionHandler|\btry[[:space:]]*\{|\bcatch[[:space:]]*\()'
        report "controller" "A controller method builds the DTO, calls one service method and returns ApiResponse. Move logic and queries to the service, take the user as @ActorId, and let GlobalExceptionHandler render errors."
        ;;
    */service/* | */strategy/*)
        check "persistence API" '\b(EntityManager|JdbcTemplate|NamedParameterJdbcTemplate)\b'
        check "web type" '\b(HttpServletRequest|HttpServletResponse|ResponseEntity|HttpStatus)\b'
        check "security context" '\bSecurityContextHolder\b'
        check "web mapping" '@(Request|Get|Post|Put|Patch|Delete)Mapping'
        check "HTTP exception" '\bResponseStatusException\b'
        report "service" "A service works through repositories, receives the user in the DTO, throws domain exceptions and knows nothing about HTTP."
        ;;
    */repository/*)
        check "transaction" '@Transactional'
        check "security context" '\bSecurityContextHolder\b'
        check "web type" '\bHttpServletRequest\b'
        report "repository" "A repository only reads and writes. The transaction boundary belongs to the service and the current user arrives as a parameter."
        ;;
    */entity/*)
        check "repository access" '[A-Z][A-Za-z0-9]*Repository\b'
        check "injected dependency" '@Autowired'
        check "security context" '\bSecurityContextHolder\b'
        check "Lombok @Data" '@Data\b'
        check "ordinal enum" 'EnumType\.ORDINAL'
        check "eager fetch" 'FetchType\.EAGER'
        report "entity" "An entity only maps a table: explicit columns, LAZY associations, STRING enums, static factories. Move queries to the repository and logic to a service."
        ;;
    */request/* | */dto/* | */response/*)
        check "repository access" '[A-Z][A-Za-z0-9]*Repository\b'
        check "persistence API" '\bEntityManager\b'
        check "injected dependency" '@(Autowired|Component|Service)\b'
        report "request/dto/response" "Requests, DTOs and responses are plain records that only carry and validate data."
        ;;
esac

found=""
check "field injection" '@Autowired'
check "console output" '(System\.(out|err)\.print|\.printStackTrace\(\))'
if [ -n "$found" ]; then
    problems="${problems}- Clean-code rule broken: $found.
  Use constructor injection with private final fields, and SLF4J for logging.
"
fi

[ -z "$problems" ] && exit 0

{
    echo "$(basename "$path"):"
    printf '%s' "$problems"
    echo "Fix these now. If a finding is a false positive, say why in your summary and continue."
} >&2
exit 2
