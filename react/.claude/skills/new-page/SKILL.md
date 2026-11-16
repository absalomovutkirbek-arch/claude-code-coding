---
name: new-page
description: Build a route-level page that shows backend data with loading, error, empty and data states, URL-driven filters and pagination, a lazy route and a test. Use for any new screen or route.
argument-hint: "[feature] [PageName] [route path] [what it shows]"
---

# New page

Build the page `$ARGUMENTS`.

Reference: `.claude/skills/new-api-resource/reference/src/features/billing/pages/TransfersPage.tsx.tpl`, its test next to it, and `components/TransferTable.tsx.tpl`.

## 1. Clarify

State in a few lines and confirm anything unclear with the developer:

- Route path and its parameters. Who may open it.
- Which data it shows and which hooks provide it. If a hook is missing, run `/new-api-resource` first.
- Filters, sorting, pagination. What is shown when there is nothing.
- Actions on the page (create, edit, delete, operations) and what happens after each.
- Design: a mockup or an existing page to match. Do not invent a layout when the project has a design system; use its components.

## 2. Build

1. Presentational components in `components/` for the data (table, card, details). Props in, callbacks out.
2. `pages/<Name>Page.tsx`:
   - read route params and search params; validate and clamp them;
   - call the feature's hooks;
   - render the four states: loading, error (`ErrorMessage` with retry), empty, data;
   - keep filters and the page number in the URL with `useSearchParams`.
3. Route in the feature's `routes.tsx`, loaded lazily:

```tsx
{
  path: '/billing/transfers',
  lazy: async () => ({ Component: (await import('./pages/TransfersPage')).TransfersPage }),
},
```

4. A detail page validates its ID before using it:

```tsx
const id = Number(useParams().id);
const transfer = useTransfer(id); // the hook sets `enabled: Number.isInteger(id) && id > 0`
```

   A `not_found` error code renders the "not found" state, not the generic error.

## 3. Rules

- The page has no `http`, no `useQuery` / `useMutation`, no mapping of data. If it needs a calculation, that is a pure function in `model/` or `shared/lib/` with a unit test.
- Destructive actions ask for confirmation and show the pending state.
- One `<h1>`, content inside `<main>`, controls reachable by keyboard.
- Texts follow the i18n choice in "Project facts".

## 4. Test

`pages/<Name>Page.test.tsx` with `renderWithProviders()` and MSW handlers from the feature's `test/handlers.ts`:

- data state shows the important fields, formatted;
- empty state;
- error state with the retry button;
- URL-driven behaviour: the page from the query string is requested, changing a filter or the page sends the new request.

## 5. Verify and report

1. `npm run typecheck`, `npm run lint`, `npx vitest run src/features/<feature>/pages`.
2. Open the route in the dev server if it is running and the developer wants a visual check; otherwise say that the layout was not checked visually.
3. Report: route, files by layer, states handled, what was assumed about design or behaviour.
