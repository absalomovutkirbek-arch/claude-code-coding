---
name: arch-review
description: Review changed code against the project architecture and clean-code rules and report violations by layer. Use before finishing a feature, before a commit, or when asked to review a diff, a file or a module.
argument-hint: "[path | module | empty for the current git diff]"
---

# Architecture review

Review target: `$ARGUMENTS`. When empty, review the uncommitted changes (`git diff HEAD` plus untracked files). For a path or module, review those files.

Report findings. Do not fix anything unless the developer asks.

## Checklist

**Controller**
- [ ] One controller per resource; each handler method: `request.toDto(actorId)` -> one service call -> `ApiResponse`. No conditions, loops, repositories, `@Transactional`, `ResponseEntity` or `try/catch`.
- [ ] The user arrives as `@ActorId long actorId`; IDs use `{id:\\d+}`.
- [ ] Constructor injection of services only.

**Request / DTO / Response**
- [ ] Request record checks format only (Bean Validation) and builds the DTO in `toDto()`; wrapper types with `@NotNull` for required fields.
- [ ] DTO is a record, fully typed, enums instead of strings.
- [ ] Response is a record built by `from(entity)`. No entity, `Map` or `Page` leaves a controller.

**Service**
- [ ] No `EntityManager`, `JdbcTemplate`, `HttpServletRequest`, `SecurityContextHolder`, request/response records or `@Autowired` fields.
- [ ] Every business rule that can reject throws a specific domain exception with a stable error code.
- [ ] Multi-row writes and read-then-write decisions are one public `@Transactional` method; mutable values are locked; no self-invocation of transactional methods.
- [ ] Events are published for `@TransactionalEventListener(AFTER_COMMIT)` listeners. No external calls inside a transaction.
- [ ] Pattern use matches its trigger in `common/design-patterns.md`: no pipeline for 1-2 steps, no strategy for one variant, and no growing `if`/`switch` where a strategy is due.

**Repository / Entity**
- [ ] All queries are in repositories with bound parameters; no `@Transactional` and no business decisions there.
- [ ] No N+1: lists use `join fetch` or `@EntityGraph` for what the response needs; associations are `LAZY`.
- [ ] Entities map columns explicitly, have a protected no-arg constructor and static factories, no public setters for everything, no business rules, no Lombok `@Data`.
- [ ] Other modules' data is referenced by ID and reached through the module's `contract` interface.

**Database**
- [ ] Schema change is a new Flyway migration in the module's folder; no committed migration was edited.
- [ ] Foreign keys with indexes, `NOT NULL`, `CHECK` for enums, correct money and time types; entity mapping matches (`ddl-auto=validate`).
- [ ] Table is in its module's schema; no cross-module table access in code.

**API**
- [ ] Route is explicit, versioned and plural; verb and status code match `common/api-design.md`.
- [ ] Response uses the standard envelope; lists paginate; JSON is `snake_case` without per-field annotations.
- [ ] Authentication and record-level authorization are present.

**Clean code**
- [ ] Names follow the vocabulary and suffix rules; no magic values; no dead code, `System.out` or `printStackTrace()`.
- [ ] Methods are short, single-purpose, with at most 3 parameters (constructors of components and records excepted).
- [ ] No duplicated business knowledge; no speculative abstractions; no `Optional` parameters or fields.

**Tests and security**
- [ ] Service methods, handlers and strategies have unit tests without a Spring context covering each rejecting rule; the endpoint has an API test on PostgreSQL.
- [ ] No secrets in code, properties or logs; input is validated; queries are parameterized.

## Output format

```
## Verdict: PASS | PASS WITH NOTES | CHANGES NEEDED

### Must fix
- <file>:<line> [layer] What is wrong. Which rule. How to fix it.

### Should fix
- ...

### Notes
- ...

### Checked and fine
- <one line per layer>
```

Order findings by severity. Every finding names the file and line, the rule it breaks and a concrete fix. Do not report style preferences that no rule covers. Legacy code outside the review target is not a finding; mention it under Notes at most once.
