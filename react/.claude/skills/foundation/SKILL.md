---
name: foundation
description: Install the shared kernel (src/shared) and the test setup that every feature depends on - HTTP client, ApiError, envelope types, query client, server error mapping for forms, money and date helpers, MSW test server. Use once per project, or when src/shared/api is missing.
---

# Foundation: install the shared kernel

Install the kernel from `${CLAUDE_SKILL_DIR}/templates/` into this project. It is tested code. Copy it as is; do not rewrite or "improve" it.

## 1. Inspect first

- Read "Project facts" in `CLAUDE.md` for the package manager, aliases and commands.
- If `src/shared/` already has an API client, an error type or a query client, list what is there and install only what is missing. Never overwrite an existing file without asking. If the project has its own API client, do not add a second one: record the mapping in "Project facts" instead.
- Check `package.json`. Runtime packages: `react`, `react-router-dom`, `@tanstack/react-query`, `axios`, `react-hook-form`, `@hookform/resolvers`, `zod`. Dev packages: `typescript`, `vitest`, `jsdom`, `@testing-library/react`, `@testing-library/user-event`, `@testing-library/jest-dom`, `msw`. List what is missing and ask before installing.

## 2. Copy

Copy every file under `templates/src/` to `src/`, removing the `.tpl` suffix and keeping the folder structure.

| File | Purpose |
| --- | --- |
| `shared/api/http.ts` | The only module that talks to the network: base URL, bearer token, envelope, `ApiError` |
| `shared/api/ApiError.ts` | Normalised failure with `status`, `code`, `details`, `fieldErrors` |
| `shared/api/types.ts` | `ApiSuccess`, `PageMetaDto`, `Page`, `toPage()` |
| `shared/api/queryClient.ts` | TanStack Query defaults (no retry on 4xx) |
| `shared/auth/tokenStore.ts` | Where the access token is kept (in memory by default) |
| `shared/forms/applyServerErrors.ts` | Server errors -> react-hook-form field and form errors |
| `shared/lib/money.ts`, `dates.ts` | Minor units and ISO timestamps, parsing and formatting |
| `shared/ui/ErrorMessage.tsx`, `Pagination.tsx` | Minimal presentational pieces; replace their markup with the project's UI kit |
| `app/providers.tsx` | `QueryClientProvider` |
| `test/setup.ts`, `server.ts`, `render.tsx` | Vitest + Testing Library + MSW setup |

## 3. Wire the configuration

`vite.config.ts` (import `defineConfig` from `vitest/config` so that the `test` block is typed):

```ts
resolve: {
  alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
},
test: {
  environment: 'jsdom',
  setupFiles: ['./src/test/setup.ts'],
  css: false,
},
```

`tsconfig.app.json` (`compilerOptions`):

```json
"strict": true,
"paths": { "@/*": ["./src/*"] }
```

`package.json` scripts, if they are missing: `"typecheck": "tsc -b"`, `"test": "vitest run"`, `"test:watch": "vitest"`.

`src/main.tsx`: wrap the router in `<AppProviders>`. The reference is `.claude/skills/new-api-resource/reference/src/main.tsx.tpl`.

`.env.example`: add `VITE_API_URL=/api/v1`. For local development, proxy `/api` to the backend in `vite.config.ts` (`server.proxy`) instead of hard-coding a host.

Two places are adapted to the project, and nowhere else:

- `shared/auth/tokenStore.ts`: how the token is obtained and kept (login flow, refresh, httpOnly cookie).
- The app shell calls `setUnauthorizedHandler()` once to decide what a 401 does (usually: clear the session and go to the login page).

MSW version: `src/test/setup.ts` uses `onUnhandledFrame` (MSW 3). On MSW 2 the option is `onUnhandledRequest`.

## 4. Verify

- `npm run typecheck` and `npm run lint` pass.
- `npm run test` runs `shared/lib/money.test.ts` green.
- `npm run build` succeeds.

## 5. Report

List the files created, the config changes, anything skipped because it already existed, the packages the developer still has to approve, and the two adaptation points above.
