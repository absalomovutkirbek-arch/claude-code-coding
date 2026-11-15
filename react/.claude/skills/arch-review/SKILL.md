---
name: arch-review
description: Review changed frontend code against the project architecture and clean-code rules and report violations by layer. Use before finishing a feature, before a commit, or when asked to review a diff, a file or a feature.
argument-hint: "[path | feature | empty for the current git diff]"
---

# Architecture review

Review target: `$ARGUMENTS`. When empty, review the uncommitted changes (`git diff HEAD` plus untracked files). For a path or feature, review those files.

Report findings. Do not fix anything unless the developer asks.

## Checklist

**Page**
- [ ] Reads URL params, calls hooks, composes components. No `http`, `useQuery` / `useMutation`, data mapping or calculations.
- [ ] Loading, error (with retry), empty and data states are all rendered; `not_found` has its own state on detail pages.
- [ ] Filters and pagination live in the URL and are validated before use.

**Component**
- [ ] Props in, callbacks out; presentational components know nothing about queries or routing.
- [ ] No fetching or derived state in `useEffect`; no server data copied into `useState`.
- [ ] Money, dates and enum labels are formatted with the shared helpers and typed label maps.
- [ ] Accessible: real buttons and links, labels on inputs, `role="alert"` on errors, stable list keys.

**Form**
- [ ] zod schema with format rules only; form values are strings; `toInput()` converts once (minor units via `toMinorUnits()`).
- [ ] `useForm` + `zodResolver` + `defaultValues`; submit through the mutation hook; server errors through `applyServerErrors()`.
- [ ] Submit is disabled only while pending.

**Data layer**
- [ ] Only `api/*.api.ts` calls `http`; no `axios` or `fetch` elsewhere; wire `Dto` types stay inside the API module and are mapped field by field.
- [ ] One hook per query or mutation; keys only from the key factory; every dependency is in the key.
- [ ] Mutations invalidate exactly what they change; no manual cache writes without a reason.
- [ ] Errors are decided by `error.code`; texts for codes live in the feature's `errors.ts`.

**Structure**
- [ ] Files are in the right feature and folder; names follow the conventions; named exports only.
- [ ] Other features are imported only through their `index.ts`; `shared/` imports nothing from `features/`.
- [ ] Routes are registered through the feature's `routes.tsx` and load pages lazily.

**TypeScript and clean code**
- [ ] No `any`, unsafe `as`, `@ts-ignore`, `enum` or non-null `!`.
- [ ] No magic strings for statuses or error codes; no dead code, `console.log` or commented-out code.
- [ ] Components and functions are small and single-purpose; no premature `useMemo` / `useCallback`; no speculative abstractions.

**Tests and security**
- [ ] Schemas, API modules, forms and pages with behaviour have tests; the backend is mocked with MSW, not `vi.mock`.
- [ ] No tokens or personal data in `localStorage` or logs; no secrets in `VITE_` variables; no `dangerouslySetInnerHTML`.

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
