# Project guide (Yii2)

You write the code; the developer provides the business logic. Follow the architecture below without being asked, and ask only about business behaviour.

## Project facts

<!-- Fill once per project. Run /adopt-project to fill this section from the code. -->

- **Domain**: _what the product does, in 3-5 lines_
- **Template / root namespace**: basic, `app\`
- **PHP / database**: 8.1+, PostgreSQL (one schema per module)
- **Modules root / shared kernel**: `modules/`, `core/`
- **API prefix / auth**: `/v1`, bearer token (`HttpBearerAuth`)
- **JSON casing / table naming / money**: `snake_case`, singular tables, integer minor units
- **Run tests**: `vendor/bin/codecept run unit`
- **Static analysis / code style**: `vendor/bin/phpstan analyse`, `vendor/bin/php-cs-fixer fix`
- **Migrations**: `php yii migrate/create '<namespace>\<Name>'`, apply with `php yii migrate` (ask first)
- **Existing modules**: _name: one line each_
- **Project-specific overrides**: _none_

When a value here contradicts a rule file, this section wins.

## Request path

```
routes.php -> Controller (actions map) -> Action -> Form -> DTO -> Service -> Repository -> ActiveRecord
                                             Resource <- model / Page <-'
```

| Piece | One-line rule |
| --- | --- |
| Controller | Only `actions()` and `verbs()` |
| Action | Validate, call one service method, return a resource |
| Form | Input format rules and `toDto()` |
| DTO | Immutable typed input |
| Service | Use case, business rules, transaction, events after commit |
| Repository | Every query and write, behind an interface |
| Model | Table mapping only |
| Resource | The only place that builds response arrays |

## Always

1. Put code in the layer that owns it. If unsure, see "Where does new code go" in `.claude/rules/common/architecture.md`.
2. Inject dependencies through constructors. No `Yii::$app` in services, repositories, DTOs, resources.
3. Wrap multi-table writes and read-then-write decisions in `TransactionManagerInterface::run()`. Side effects go after commit through events.
4. Throw domain exceptions for failures. Never return `false`/`null` as an error, never `try/catch` in actions.
5. Use a pattern only when its trigger in `.claude/rules/common/design-patterns.md` is met.
6. Every schema change is a migration in the owning module. Never edit a committed migration.
7. Every service method, handler and strategy gets unit tests in the same task.
8. `declare(strict_types=1);`, `final` classes, full type declarations, enums instead of magic values.
9. Ask before inventing a business rule. Decide technical structure yourself.
10. Do not refactor code unrelated to the task; report what you noticed.

## Rules

Loaded from `.claude/rules/`:

- `common/` - stack-agnostic: architecture, clean-code, design-patterns, api-design, validation-and-errors, database, testing, security, workflow.
- `yii2/structure.md` - folder layout, layer mapping, wiring (always loaded).
- `yii2/http-layer.md`, `service-layer.md`, `data-layer.md`, `testing.md` - loaded when you work on matching files. Read the matching one before creating a new file in that layer.

## Skills

| Command | Use for |
| --- | --- |
| `/adopt-project` | First run in a project: fill "Project facts", compare the code with the standard |
| `/foundation` | Install the shared kernel `core/` (once per project) |
| `/new-module` | A new business module with its schema |
| `/new-endpoint` | An endpoint as a full vertical slice with tests |
| `/new-migration` | Any schema change |
| `/pipeline` | A use case with 3+ steps as Chain of Responsibility |
| `/strategy` | 2+ interchangeable variants of one job |
| `/arch-review` | Review a diff, file or module against the rules |

The tested reference slice is `.claude/skills/new-endpoint/reference/` (module `billing`). Copy its shape.

## Sessions without skills or hooks

Some sessions load this file but not `.claude/skills/`, the path-scoped rule files or the hooks in `.claude/settings.json` (for example cloud threads of a claude.ai project). Check whether the skills above are available to you; when they are not:

- Treat the Skills table as a list of procedures. When a task matches one, or the developer names its command, read `.claude/skills/<name>/SKILL.md` and follow it. `$ARGUMENTS` is the developer's request and `${CLAUDE_SKILL_DIR}` is `.claude/skills/<name>`.
- Before writing code in a layer, read the matching file in `.claude/rules/yii2/` yourself.
- Before reporting the work as done, run `php .claude/hooks/check-changed.php origin/main` (use the branch you started from if it is not `main`) and fix every finding. It applies the same layer checks as the edit hook to everything you changed.

## Definition of done

- Code is in the right layers and passes `/arch-review`.
- Lint, static analysis and the relevant tests were run; results are reported.
- Routes, container bindings and event listeners are registered.
- The summary lists files by layer, schema changes, business rules with error codes, assumptions and open questions.
