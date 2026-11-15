# React: structure and layer mapping

This file maps the stack-agnostic rules in `.claude/rules/common/` onto a React single-page application (TypeScript, Vite, React Router, TanStack Query, react-hook-form, zod). The frontend mirrors the backend's layers, so the same thinking applies on both sides.

## Folder layout

```
src/
  main.tsx                       mounts providers and the router, nothing else
  app/
    providers.tsx                QueryClientProvider and other app-wide providers
    router.tsx                   all routes; spreads each feature's route array
  shared/                        Shared kernel (feature-agnostic). Created by /foundation
    api/      http.ts, ApiError.ts, types.ts, queryClient.ts
    auth/     tokenStore.ts
    forms/    applyServerErrors.ts
    lib/      money.ts, dates.ts and other pure helpers
    ui/       reusable presentational components (ErrorMessage, Pagination, kit wrappers)
    hooks/    generic hooks (useDebounce)
  features/<feature>/            one backend module or one business area
    model/<entity>.ts            types and `as const` enums in camelCase
    api/<resource>.api.ts        the only code calling http; wire DTO <-> model mapping
    hooks/<resource>Keys.ts      query key factory
    hooks/use<Thing>.ts          one query or mutation per file
    schemas/<form>.schema.ts     zod schema, form values type, defaults, toInput()
    components/<Name>.tsx        feature components
    pages/<Name>Page.tsx         route-level components
    errors.ts                    error code -> user text of this feature
    routes.tsx                   RouteObject[] of the feature, pages loaded lazily
    index.ts                     public API of the feature
    test/handlers.ts             MSW handlers and wire fixtures for tests
  test/                          setup.ts, server.ts, render.tsx
```

Tests sit next to the file they test: `<name>.test.ts(x)`. Create a folder only when its first file appears. A canonical, tested example is in `.claude/skills/new-api-resource/reference/`.

## Layer mapping

| Layer | File | Key rule |
| --- | --- | --- |
| Page (= controller/action) | `pages/<Name>Page.tsx` | Reads route and search params, calls hooks, composes components, renders the four states. No `http`, no `useQuery`, no data transformation |
| Component | `components/<Name>.tsx`, `shared/ui/` | Named function component with a `Props` interface. Data through props, changes through callbacks |
| Schema (= form) | `schemas/<form>.schema.ts` | Format rules only, plus `toInput()` that builds the API input |
| Hook (= service) | `hooks/use<Thing>.ts` | Wraps exactly one `useQuery` or `useMutation`; owns keys and invalidation |
| API module (= repository) | `api/<resource>.api.ts` | Async functions that call `http` and return models. Wire DTO types never leave the file |
| Model (= DTO) | `model/<entity>.ts` | Interfaces and `as const` enums. No classes, no logic beyond pure helpers |

## Import rules

- Use the `@/` alias for `src/`. Relative imports only inside one feature.
- Allowed direction: `app` -> `features` -> `shared`. Never the other way.
- A feature imports another feature only from its `index.ts` (`@/features/billing`), never from its inner folders.
- `index.ts` exports what other code may use: routes, a few components, hooks and types. API modules, DTOs and schemas stay private unless needed elsewhere.
- Named exports everywhere. No default exports.
- `axios` is imported only in `shared/api/http.ts`.

## State

| Kind | Where |
| --- | --- |
| Server data | TanStack Query (the feature's hooks). Never duplicated |
| Filters, pagination, selected tab, anything worth a link | URL search params |
| Form values | react-hook-form |
| Local UI state (open, hovered, step) | `useState` in the component |
| App-wide client state (session, theme, locale) | A small context under `app/` or `shared/`. A store library only if "Project facts" names one |

## TypeScript and React rules

- `strict` stays on. No `any`, no `as` to silence the compiler (allowed: `as const`, narrowing after a runtime check), no `@ts-ignore`, no non-null `!` except on `document.getElementById('root')`.
- No `enum`, no namespaces, no parameter properties: the project compiles with `erasableSyntaxOnly`. Enums are `as const` objects with a derived union type.
- Function components and hooks only. No class components. Props are an `interface Props`; no `React.FC`.
- Derive values during render. `useEffect` is for synchronising with something outside React (subscriptions, document title), never for fetching or for copying props into state.
- Do not add `useMemo` / `useCallback` / `memo` without a measured reason.
- Lists use a stable `key` from the data, never the array index.
- Every interactive element is a real `<button>`, `<a>` or form control with an accessible name. Inputs have a `<label>`.
- No `dangerouslySetInnerHTML`. No tokens or personal data in `localStorage`. No secrets in `VITE_` variables: they are public.
- User-facing text follows the i18n choice in "Project facts"; texts for error codes live in the feature's `errors.ts`.

## Existing projects

When the project does not yet follow this layout: read "Project facts" in `CLAUDE.md`, apply the layout to new features and new pages, and keep old screens working. If `src/shared/api/` is missing, run `/foundation` first. See `common/workflow.md` for the legacy rules.
