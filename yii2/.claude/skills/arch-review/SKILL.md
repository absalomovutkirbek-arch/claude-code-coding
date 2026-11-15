---
name: arch-review
description: Review changed code against the project architecture and clean-code rules and report violations by layer. Use before finishing a feature, before a commit, or when asked to review a diff, a file or a module.
argument-hint: "[path | module | empty for the current git diff]"
---

# Architecture review

Review target: `$ARGUMENTS`. When empty, review the uncommitted changes (`git diff HEAD` plus untracked files). For a path or module, review those files.

Report findings. Do not fix anything unless the developer asks.

## Checklist

**Controller / Action**
- [ ] Controller has only `actions()` and `verbs()`.
- [ ] Action: validate -> one service call -> resource. No conditions, loops, queries, `save()`, transactions or `try/catch`.
- [ ] Dependencies injected through the constructor.

**Form / DTO**
- [ ] Form checks format only and builds the DTO in `toDto()`.
- [ ] DTO is final, readonly, fully typed, enums instead of strings.
- [ ] No raw request arrays travel past the form.

**Service**
- [ ] No `Yii::$app`, no ActiveQuery / `Query` / `createCommand`, no request or response.
- [ ] Every business rule that can reject throws a specific domain exception with a stable error code.
- [ ] Multi-table writes and read-then-write decisions run inside `TransactionManagerInterface::run()`; mutable values are locked.
- [ ] Events are dispatched after the transaction, not inside it. No external calls inside a transaction.
- [ ] Pattern use matches its trigger in `common/design-patterns.md`: no pipeline for 1-2 steps, no strategy for one variant, and no growing `if`/`switch` where a strategy is due.

**Repository / Model**
- [ ] All queries are in repositories; repositories return models, `Page` or scalars, never queries.
- [ ] No N+1: collections eager-load what the resource uses.
- [ ] Models have no `rules()`, queries or business logic.
- [ ] Interface bound in `config/container.php`.

**Database**
- [ ] Schema change has a migration with a real `safeDown()`.
- [ ] Foreign keys, indexes, `NOT NULL`, `CHECK` for enums, correct money and time types.
- [ ] Table is in its module's schema; no cross-module table access in code.

**API**
- [ ] Route is explicit, versioned and plural; verb and status code match `common/api-design.md`.
- [ ] Response goes through a resource and the standard envelope; lists paginate.
- [ ] Authentication and record-level authorization are present.

**Clean code**
- [ ] Names follow the vocabulary and suffix rules; no magic values; no dead code or debug output.
- [ ] Functions are short, single-purpose, with at most 3 parameters.
- [ ] No duplicated business knowledge; no speculative abstractions.

**Tests and security**
- [ ] Service methods, handlers and strategies have unit tests covering each rejecting rule.
- [ ] No secrets in code or logs; input is validated; SQL is parameterized.

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
