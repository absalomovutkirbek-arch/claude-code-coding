---
name: adopt-project
description: Onboard this Claude Code setup onto a project - inspect the codebase, fill the Project facts in CLAUDE.md, and report how the existing code differs from the standard. Use right after installing the setup into a new or existing project.
disable-model-invocation: true
---

# Adopt project

Connect this setup to the project it was just installed into. This skill inspects and documents. It does not refactor.

## 1. Inspect

Gather facts from the code, not from assumptions:

- `package.json` and the lock file: package manager (npm, pnpm, yarn), React version, build tool (Vite, Next.js, CRA), TypeScript or JavaScript, router, data library (TanStack Query, RTK Query, SWR, plain axios), state library (Redux, Zustand, MobX), form and validation libraries, UI kit and styling (MUI, Ant Design, shadcn/ui, Tailwind, CSS modules), i18n library, test tools (Vitest or Jest, Testing Library, MSW, Playwright or Cypress), lint and format tools, the scripts and their exact names.
- `tsconfig*.json`: `strict`, path aliases, `erasableSyntaxOnly`.
- Environment: variable names from `.env.example` (never read `.env` or `.env.local`), how the API base URL is set.
- Existing structure: by type (`components/`, `pages/`, `services/`, `store/`) or by feature; where API calls are made; how responses and errors are handled; how authentication and the token work; how routes are declared and protected.
- The backend contract in use: envelope shape, JSON casing, error format, pagination format. Read an existing API call and its types; do not guess.
- Conventions already in place: file naming (PascalCase or kebab-case), export style, where tests live.

## 2. Fill "Project facts" in CLAUDE.md

Replace the placeholder values with what you found, including the exact commands for typecheck, lint, tests and build. Add a 3-5 line description of the product and list existing features with one line each. If something cannot be determined, write `unknown - ask` and include it in the questions.

## 3. Classify the project

- **New / empty**: propose running `/foundation`, then `/new-feature` for the first feature.
- **Existing, compatible**: already feature-based with a central API client and a query library. Map its names onto the standard (for example its `services/` = our `api/`, its `views/` = our `pages/`) and record the mapping in "Project facts" so new code follows the existing names.
- **Existing, different** (API calls inside components, server data in Redux or `useState`, JavaScript, no tests): record that new features follow the standard under `src/features/` and `src/shared/`, while old screens stay as is and are improved only where touched.

## 4. Conflicts between the project and the standard

Where the project already has an established convention that differs from the rules (another data library, a global store for server data, `fetch` wrapper instead of axios, another envelope or `camelCase` API, default exports, Jest, JavaScript, Next.js routing), do not change it. List each conflict with two options, keeping the project's way or migrating to the standard, and a recommendation. Record the developer's decision in "Project facts" under "Project-specific overrides".

## 5. Report

```
## Project profile
<facts table>

## How new code will be written here
<5-8 lines: where features live, aliases, commands>

## Differences from the standard
| Area | Project today | Standard | Recommendation |

## Questions
<only product, design or decision questions that the code cannot answer>

## Suggested first steps
1. ...
```

Do not create, move or rewrite application code in this skill. The only file edited is `CLAUDE.md`.
