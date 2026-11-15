# Project guide (Laravel)

You write the code; the developer provides the business logic. Follow the architecture below without being asked, and ask only about business behaviour.

## Project facts

<!-- Fill once per project. Run /adopt-project to fill this section from the code. -->

- **Domain**: _what the product does, in 3-5 lines_
- **Laravel / PHP / database**: 11+, 8.2+, PostgreSQL (one schema per module)
- **Modules root / shared kernel**: `app/Modules/`, `app/Core/`
- **API prefix / auth**: `/api/v1/<module>`, Sanctum (`auth:sanctum`)
- **JSON casing / table naming / money**: `snake_case`, plural tables, integer minor units
- **Run tests**: `php artisan test`
- **Static analysis / code style**: `vendor/bin/phpstan analyse`, `vendor/bin/pint`
- **Migrations**: `php artisan make:migration <name> --path=app/Modules/<Module>/Database/Migrations`, apply with `php artisan migrate` (ask first)
- **Existing modules**: _name: one line each_
- **Project-specific overrides**: _none_

When a value here contradicts a rule file, this section wins.

## Request path

```
routes/api.php -> Action (invokable) -> FormRequest -> DTO -> Service -> Repository -> Eloquent model
                                           JsonResource <- model / paginator <-'
```

| Piece | One-line rule |
| --- | --- |
| Route | Points straight at one Action class. No controllers with many methods |
| Action | `__invoke()`: one service call, return through `ApiResponse` and a resource |
| FormRequest | Input format rules and `toDto()` |
| DTO | Immutable typed input |
| Service | Use case, business rules, transaction, events after commit |
| Repository | Every query and write, behind an interface |
| Model | Table mapping only |
| Resource | The only place that builds response arrays |

## Always

1. Put code in the layer that owns it. If unsure, see "Where does new code go" in `.claude/rules/common/architecture.md`.
2. Inject dependencies through constructors. No facades, `app()`, `request()`, `auth()` in services, repositories, DTOs, resources.
3. Wrap multi-table writes and read-then-write decisions in `TransactionManagerInterface::run()`. Side effects go after commit through events.
4. Throw domain exceptions for failures. Never return `false`/`null` as an error, never `try/catch` in actions.
5. Use a pattern only when its trigger in `.claude/rules/common/design-patterns.md` is met.
6. Every schema change is a migration in the owning module. Never edit a committed migration.
7. Every service method, handler and strategy gets unit tests in the same task; every endpoint gets a feature test.
8. `declare(strict_types=1);`, `final` classes, full type declarations, enums instead of magic values.
9. Ask before inventing a business rule. Decide technical structure yourself.
10. Do not refactor code unrelated to the task; report what you noticed.

## Rules

Loaded from `.claude/rules/`:

- `common/` - stack-agnostic: architecture, clean-code, design-patterns, api-design, validation-and-errors, database, testing, security, workflow.
- `laravel/structure.md` - folder layout, layer mapping, wiring (always loaded).
- `laravel/http-layer.md`, `service-layer.md`, `data-layer.md`, `testing.md` - loaded when you work on matching files. Read the matching one before creating a new file in that layer.

## Skills

| Command | Use for |
| --- | --- |
| `/adopt-project` | First run in a project: fill "Project facts", compare the code with the standard |
| `/foundation` | Install the shared kernel `app/Core/` (once per project) |
| `/new-module` | A new business module with its provider and schema |
| `/new-endpoint` | An endpoint as a full vertical slice with tests |
| `/new-migration` | Any schema change |
| `/pipeline` | A use case with 3+ steps as Chain of Responsibility |
| `/strategy` | 2+ interchangeable variants of one job |
| `/arch-review` | Review a diff, file or module against the rules |

The tested reference slice is `.claude/skills/new-endpoint/reference/` (module `Billing`). Copy its shape.

## Definition of done

- Code is in the right layers and passes `/arch-review`.
- Pint, static analysis and the relevant tests were run; results are reported.
- Routes, container bindings and event listeners are registered in the module's service provider.
- The summary lists files by layer, schema changes, business rules with error codes, assumptions and open questions.
