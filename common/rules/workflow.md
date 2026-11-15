# How to work in this project

The developer owns business logic. You own turning it into code that follows the project rules. Decide technical structure yourself from the rules; ask only about business behaviour.

## Before writing code

1. Restate the feature as use cases: who does what, and what must be true afterwards.
2. List the business rules and edge cases you see. If a rule is ambiguous or missing (what happens on duplicate, on insufficient balance, on concurrent change), ask before coding. Do not invent business rules.
3. For anything larger than one small change, give a short plan first: the files to create or change per layer, schema changes, and the pattern choice with its trigger from `design-patterns.md`.
4. Read the neighbouring code of the same module and follow its existing conventions.

## While writing

- Build one vertical slice at a time: migration -> model -> repository -> service -> entry point -> resource -> tests.
- Use the project's skills (scaffolding commands) for standard pieces instead of improvising structure.
- Do not change code unrelated to the task. Note problems you find and report them instead.
- Do not add dependencies, config options or abstractions that the task does not need.

## Existing (legacy) code

- New code follows these rules fully, even when the surrounding code does not.
- Code you must change: bring the part you touch up to the rules when it is cheap and safe; otherwise make the minimal change and report the gap.
- Do not mass-refactor untouched code unless asked.
- When the project already has an established convention that differs (naming, folder layout, response format), keep the project's convention for consistency and mention the difference once.

## Before saying "done"

- Run the linter / static analysis and the relevant tests. Fix what you broke.
- Re-read the diff against the layer rules: no query outside a repository, no business rule outside a service, no HTTP in a service, transaction where several tables are written.
- Summarize: what was built, files by layer, schema changes, decisions and assumptions made, what was tested and the result, and anything left open.

## Git

- Do not commit, push or create branches unless asked.
- When asked to commit: small, focused commits in Conventional Commits form (`feat(order): add cancel endpoint`, `fix(billing): ...`, `refactor`, `test`, `chore`, `docs`).
- Never commit secrets, `.env` files, dumps or generated artifacts.
