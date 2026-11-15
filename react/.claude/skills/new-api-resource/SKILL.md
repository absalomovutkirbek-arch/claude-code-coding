---
name: new-api-resource
description: Connect a backend resource or endpoint to the frontend as a full data slice - model types, API module with wire mapping, query keys, query and mutation hooks, MSW handlers and tests. Use whenever the UI needs data from, or sends data to, a backend endpoint that is not connected yet.
argument-hint: "[feature] [resource] [endpoints, e.g. list, view, create]"
---

# New API resource (data slice)

Connect `$ARGUMENTS`.

The canonical, tested example of every file is in `${CLAUDE_SKILL_DIR}/reference/src/features/billing/` (resource `transfers`). Read the matching reference file before writing each file and keep the same shape. The files end in `.tpl` only so tools do not pick them up.

## 1. Get the contract

Do not guess the API. Establish, from the backend code, its OpenAPI document or the developer:

- Method and path of each endpoint, relative to the API base URL.
- Request body and query parameters with types (wire names are `snake_case`).
- Response `data` fields with types, which are nullable, and the enum values.
- Whether the list is paginated (`meta.page`, `per_page`, `total`, `total_pages`) and which filters it accepts.
- Error codes the endpoints can return besides the standard ones, and what each means for the user.

If the backend lives in a repository you can read, read its request, response and exception classes. If a field's meaning is unclear, ask.

## 2. Build in this order

| # | File | Reference |
| --- | --- | --- |
| 1 | Model: entity type, enums, filter and input types | `model/transfer.ts.tpl` |
| 2 | API module: `Dto` type, `to<Entity>()`, one function per endpoint | `api/transfers.api.ts.tpl` |
| 3 | Query keys | `hooks/transferKeys.ts.tpl` |
| 4 | One hook per query and per mutation | `hooks/useTransfers.ts.tpl`, `useTransfer.ts.tpl`, `useCreateTransfer.ts.tpl` |
| 5 | Error-code texts of the new business codes | `errors.ts.tpl` |
| 6 | MSW handlers and wire fixtures | `test/handlers.ts.tpl` |
| 7 | API module test | `api/transfers.api.test.ts.tpl` |
| 8 | Export what other code needs from `index.ts` | `index.ts.tpl` |

Reuse the feature's existing files and add to them. One API module and one key factory per resource.

## 3. Conventions

| Operation | API function | Hook | Notes |
| --- | --- | --- | --- |
| List | `list<Entities>(filter): Promise<Page<T>>` | `use<Entities>(filter)` | `placeholderData: keepPreviousData` |
| View | `get<Entity>(id): Promise<T>` | `use<Entity>(id)` | `enabled` when the ID can be missing |
| Create | `create<Entity>(input): Promise<T>` | `useCreate<Entity>()` | invalidates `keys.lists()` |
| Update | `update<Entity>(id, input): Promise<T>` | `useUpdate<Entity>()` | invalidates `keys.lists()` and `keys.detail(id)` |
| Delete | `delete<Entity>(id): Promise<void>` | `useDelete<Entity>()` | invalidates `keys.lists()`, removes `keys.detail(id)` |
| Operation | `<verb><Entity>(id, input?)` | `use<Verb><Entity>()` | invalidates what it changes |

- Map every field explicitly in both directions. Optional wire fields become `null` or are left out consistently; never `undefined | null` mixed.
- Money stays an integer in minor units and timestamps stay ISO strings in the model.
- Mutation hooks with more than one argument take a single object: `mutationFn: ({ id, input }) => update<Entity>(id, input)`.

## 4. Verify and report

1. `npm run typecheck`, `npm run lint`.
2. Run the new test file: `npx vitest run src/features/<feature>/api`.
3. Report: endpoints connected, model and hooks created, error codes handled, anything in the contract that was assumed. Name the next step (`/new-page` or `/new-form`).
