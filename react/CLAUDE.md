# Project guide (React)

You write the code; the developer provides the business logic and the design. Follow the architecture below without being asked, and ask only about behaviour and appearance the task does not define.

## Project facts

<!-- Fill once per project. Run /adopt-project to fill this section from the code. -->

- **Product**: _what the application does and who uses it, in 3-5 lines_
- **Stack**: React 19, TypeScript (strict), Vite, React Router, TanStack Query, react-hook-form + zod, axios
- **Package manager**: npm
- **UI kit / styling**: _none yet: plain elements; name the library (MUI, Ant Design, shadcn/ui, Tailwind) once chosen_
- **Backend API**: base URL from `VITE_API_URL` (default `/api/v1`), envelope `{data, meta}` / `{error: {code, message, details}}`, `snake_case` JSON
- **Auth**: bearer token through `shared/auth/tokenStore.ts`
- **Texts / i18n**: _hard-coded English; name the i18n library and default language once chosen_
- **Money / time**: integer minor units formatted by `shared/lib/money.ts`; ISO 8601 UTC formatted by `shared/lib/dates.ts`
- **Commands**: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`
- **Existing features**: _name: one line each_
- **Project-specific overrides**: _none_

When a value here contradicts a rule file, this section wins.

## Data path

```
Route -> Page -> feature hooks (TanStack Query) -> features/<f>/api/*.api.ts -> shared/api/http.ts -> backend
           '-> components (props in, events out)        wire DTO (snake_case) <-> model (camelCase)
Form: zod schema (format) -> toInput() -> mutation hook -> ApiError -> applyServerErrors()
```

| Piece | One-line rule | Backend twin |
| --- | --- | --- |
| Page | Reads the URL, calls hooks, composes components. No fetching, no business logic | Controller / Action |
| Component | Props in, events out. Feature components may use the feature's hooks; `shared/ui` never does | Resource (view) |
| Schema | zod: format rules of a form, mirrors the backend's request validation | Form |
| Hook | `useQuery` / `useMutation` wrappers: keys, caching, invalidation | Service |
| API module | The only code that calls `http`; maps wire DTOs to models | Repository |
| Model | Types and `as const` enums of the feature in camelCase | DTO / Model |

## Always

1. Put code in the layer that owns it: see the table above and `.claude/rules/react/structure.md`.
2. Only `features/<f>/api/*.api.ts` calls `http`. No `axios`, `fetch`, `useQuery` or `useMutation` in pages or components.
3. Server data lives in TanStack Query only. Never copy it into `useState`, context or a store.
4. Errors are `ApiError`; the UI decides by `error.code`, never by status or message text. Business rules stay on the backend.
5. Every list and detail view handles four states: loading, error, empty, data.
6. A feature imports another feature only through its `index.ts`. `shared/` never imports from `features/`.
7. Strict TypeScript: no `any`, no `as` casts to silence errors, no `@ts-ignore`, no `enum` (use `as const` objects).
8. Money is integer minor units, time is ISO 8601 UTC; format only at the edge with the shared helpers.
9. Every schema, API module and component with behaviour gets tests in the same task.
10. Ask before inventing behaviour or design. Do not refactor code unrelated to the task; report what you noticed.

## Rules

Loaded from `.claude/rules/`:

- `common/` - stack-agnostic: architecture, clean-code, design-patterns, api-design, validation-and-errors, testing, security, workflow. `database.md` applies to the backend only.
- `react/structure.md` - folder layout, layer mapping, imports (always loaded).
- `react/data-layer.md`, `ui-layer.md`, `forms.md`, `testing.md` - loaded when you work on matching files. Read the matching one before creating a new file in that layer.

## Skills

| Command | Use for |
| --- | --- |
| `/adopt-project` | First run in a project: fill "Project facts", compare the code with the standard |
| `/foundation` | Install the shared kernel `src/shared/` and the test setup (once per project) |
| `/new-feature` | A new feature folder with its routes and public API |
| `/new-api-resource` | Connect a backend resource: model, API module, query hooks, test handlers |
| `/new-page` | A route-level page with the four states |
| `/new-form` | A form: zod schema, react-hook-form, server errors, tests |
| `/arch-review` | Review a diff, file or feature against the rules |

The tested reference feature is `.claude/skills/new-api-resource/reference/` (feature `billing`). Copy its shape.

## Definition of done

- Code is in the right layers and passes `/arch-review`.
- `typecheck`, `lint` and the relevant tests were run; results are reported.
- The UI handles loading, error, empty and data; forms show field and server errors; controls are reachable by keyboard and have labels.
- The summary lists files by layer, the API endpoints used, error codes handled, assumptions and open questions.
