# Project guide (Spring Boot)

You write the code; the developer provides the business logic. Follow the architecture below without being asked, and ask only about business behaviour.

## Project facts

<!-- Fill once per project. Run /adopt-project to fill this section from the code. -->

- **Domain**: _what the product does, in 3-5 lines_
- **Java / Spring Boot / build tool**: 21, 3.x, Maven (`./mvnw`)
- **Base package**: `com.example.app`
- **Modules root / shared kernel**: `<base>.modules.<module>`, `<base>.core`
- **Database / migrations**: PostgreSQL (one schema per module), Flyway SQL in `src/main/resources/db/migration/<module>/`
- **API prefix / auth**: `/api/v1/<module>`, stateless bearer token (Spring Security)
- **JSON casing / table naming / money**: `snake_case`, singular tables, `long` minor units
- **Lombok**: not used (explicit constructors and getters)
- **Run tests**: `./mvnw test` (one class: `./mvnw test -Dtest=<Class>`)
- **Compile / code style**: `./mvnw -q compile`, project formatter if configured
- **Existing modules**: _name: one line each_
- **Project-specific overrides**: _none_

When a value here contradicts a rule file, this section wins.

## Request path

```
Controller method -> Request record (Bean Validation) -> DTO -> Service -> Repository -> JPA entity
                              Response record <- entity / Page <-'
```

| Piece | One-line rule |
| --- | --- |
| Controller | One class per resource; each method is one endpoint: `toDto()`, one service call, wrap in `ApiResponse` |
| Request | Record with Bean Validation annotations and `toDto(actorId)` |
| DTO | Immutable record passed to the service |
| Service | Use case, business rules, `@Transactional`, events published for after-commit listeners |
| Repository | Spring Data interface; every query lives here |
| Entity | Table mapping only |
| Response | Record with a static `from(entity)`; the only place that shapes output |

## Always

1. Put code in the layer that owns it. If unsure, see "Where does new code go" in `.claude/rules/common/architecture.md`.
2. Constructor injection only. No `@Autowired` fields, no `SecurityContextHolder` or `HttpServletRequest` in services.
3. A use case that writes more than one row, or decides on data it read, is one `@Transactional` service method. Side effects run after commit through `@TransactionalEventListener`.
4. Throw domain exceptions for failures. Never return `null`/`false` as an error, never `try/catch` or `ResponseEntity` error bodies in controllers.
5. Use a pattern only when its trigger in `.claude/rules/common/design-patterns.md` is met.
6. Every schema change is a new Flyway migration in the owning module. Never edit a committed migration.
7. Every service method, handler and strategy gets unit tests in the same task; every endpoint gets an API test.
8. Records for requests, DTOs, responses and events. Enums instead of magic values. No entity ever leaves through a controller.
9. Ask before inventing a business rule. Decide technical structure yourself.
10. Do not refactor code unrelated to the task; report what you noticed.

## Rules

Loaded from `.claude/rules/`:

- `common/` - stack-agnostic: architecture, clean-code, design-patterns, api-design, validation-and-errors, database, testing, security, workflow.
- `spring-boot/structure.md` - package layout, layer mapping, wiring (always loaded).
- `spring-boot/http-layer.md`, `service-layer.md`, `data-layer.md`, `testing.md` - loaded when you work on matching files. Read the matching one before creating a new file in that layer.

## Skills

| Command | Use for |
| --- | --- |
| `/adopt-project` | First run in a project: fill "Project facts", compare the code with the standard |
| `/foundation` | Install the shared kernel `<base>.core` (once per project) |
| `/new-module` | A new business module with its package and schema |
| `/new-endpoint` | An endpoint as a full vertical slice with tests |
| `/new-migration` | Any schema change |
| `/pipeline` | A use case with 3+ steps as Chain of Responsibility |
| `/strategy` | 2+ interchangeable variants of one job |
| `/arch-review` | Review a diff, file or module against the rules |

The tested reference slice is `.claude/skills/new-endpoint/reference/` (module `billing`). Copy its shape.

## Sessions without skills or hooks

Some sessions load this file but not `.claude/skills/`, the path-scoped rule files or the hooks in `.claude/settings.json` (for example cloud threads of a claude.ai project). Check whether the skills above are available to you; when they are not:

- Treat the Skills table as a list of procedures. When a task matches one, or the developer names its command, read `.claude/skills/<name>/SKILL.md` and follow it. `$ARGUMENTS` is the developer's request and `${CLAUDE_SKILL_DIR}` is `.claude/skills/<name>`.
- Before writing code in a layer, read the matching file in `.claude/rules/spring-boot/` yourself.
- Before reporting the work as done, run `bash .claude/hooks/check-changed.sh origin/main` (use the branch you started from if it is not `main`) and fix every finding. It applies the same layer checks as the edit hook to everything you changed.

## Definition of done

- Code is in the right layers and passes `/arch-review`.
- The project compiles and the relevant tests were run; results are reported.
- The migration, the entity mapping and `ddl-auto=validate` agree (the API test boots the context and proves it).
- The summary lists files by layer, schema changes, business rules with error codes, assumptions and open questions.
