---
paths:
  - "src/**/*.test.ts"
  - "src/**/*.test.tsx"
  - "src/test/**/*"
  - "src/**/test/**/*.ts"
---

# React: testing

Follow `common/testing.md` for what to test. This file covers how in React.

- Vitest + Testing Library + user-event + MSW. Run with `npm run test` (one file: `npx vitest run <path>`).
- Test files sit next to the code: `money.test.ts`, `CreateTransferForm.test.tsx`. Imports from `vitest` are explicit (`describe`, `it`, `expect`, `vi`).
- Test names state behaviour: `it('shows the text for a business error code')`.

## What gets a test

| Code | Test | Minimum |
| --- | --- | --- |
| Pure helpers (`shared/lib`) | Unit | Typical values, edge cases, invalid input |
| Schema | Unit with `safeParse` | Valid values and the produced API input; each rejecting rule and the field it reports under |
| API module | Against MSW | Wire -> model mapping, model -> wire body and query string, an error becoming `ApiError` with its code |
| Form | Component test | Format errors without a request, successful submit (request body, callback), a business error code, a server field error |
| Page | Component test | Data, empty and error states; URL-driven behaviour (pagination, filters) |

Presentational components without logic are covered by the page test. Hooks that only wrap `useQuery` are covered through the components that use them.

## Rules

- The backend is mocked at the network level with MSW. Never mock `http`, API modules, hooks or `@tanstack/react-query` with `vi.mock`.
- `src/test/setup.ts` starts the MSW server and fails any request without a handler. Each test registers what it needs with `server.use(...)`.
- Handlers and wire fixtures of a feature live in `features/<feature>/test/handlers.ts` and return real envelopes: `{data, meta}` and `{error: {code, message, details}}` in `snake_case`.
- Render through `renderWithProviders()` from `src/test/render.tsx` (fresh QueryClient without retries, memory router with an optional `route`).
- Query the screen as a user would: `getByRole`, `getByLabelText`, `getByText`. `getByTestId` is the last resort. Never query by class name.
- Interact with `userEvent.setup()` and `await` every action. Wait for results with `findBy...` or `waitFor`; no fixed timeouts.
- Assert what the user sees and what was sent to the API (capture the request body or URL in the handler). Do not assert on internal state, hook calls or snapshots of whole trees.
- Fixed inputs: pass `locale` explicitly when asserting formatted money or dates.

The complete examples are under `.claude/skills/new-api-resource/reference/src/features/billing/`: `api/transfers.api.test.ts.tpl`, `schemas/createTransfer.schema.test.ts.tpl`, `components/CreateTransferForm.test.tsx.tpl`, `pages/TransfersPage.test.tsx.tpl`.
