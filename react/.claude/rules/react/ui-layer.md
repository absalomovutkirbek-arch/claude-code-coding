---
paths:
  - "src/**/pages/**/*.tsx"
  - "src/**/components/**/*.tsx"
  - "src/shared/ui/**/*.tsx"
  - "src/app/**/*.tsx"
  - "src/**/routes.tsx"
---

# React: UI layer (pages, components, routes)

## Page

```tsx
export function TransfersPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const page = Math.max(1, Number(searchParams.get('page')) || 1);
  const transfers = useTransfers({ page, perPage: PER_PAGE });

  return (
    <main>
      <h1>Transfers</h1>
      {transfers.isPending && <p>Loading...</p>}
      {transfers.isError && <ErrorMessage error={transfers.error} onRetry={() => void transfers.refetch()} />}
      {transfers.isSuccess && transfers.data.items.length === 0 && <p>No transfers yet.</p>}
      {transfers.isSuccess && transfers.data.items.length > 0 && <TransferTable transfers={transfers.data.items} />}
    </main>
  );
}
```

- A page is the controller of a route: it reads route params and search params, calls the feature's hooks and composes components. It contains no `http`, no `useQuery` / `useMutation`, no mapping or calculation of data.
- Four states, always: loading (`isPending`), error (`ErrorMessage` with retry), empty, data. Use the project's kit components for them when "Project facts" names a UI kit.
- Filters, sorting and pagination live in the URL (`useSearchParams`), so a reload or a shared link shows the same view. Parse and clamp them before use.
- Route params are strings: convert and validate (`Number(id)`, check `Number.isInteger`) before passing them to a hook.
- One `<h1>` per page, inside `<main>`.

## Component

- Named export, `interface Props`, destructured props. One component per file; small private helpers may share the file.
- Presentational components (tables, cards, `shared/ui`) get everything through props and know nothing about queries or routing.
- Feature components that own an interaction (a form, a delete button) may call the feature's mutation hook themselves and report the result through a callback prop (`onCreated`).
- Keep components under about 150 lines. Split by responsibility, not by line count: extract a child when a part has its own state or is reused.
- No data fetching in `useEffect`. No derived state: compute from props and query data during render.
- Format at the edge: `formatMoney(amount, currency)`, `formatDateTime(createdAt)`, a label map for enum values (`Record<TransferStatus, string>`), so a new enum value fails the type check.
- Conditional rendering with `&&` only on booleans (`items.length > 0 &&`, never `items.length &&`).
- Styling follows "Project facts". Do not mix a second styling approach into a project that has one, and do not add a UI library without asking.

## Accessibility

- Buttons are `<button type="button">` (or `type="submit"` in forms); navigation is `<Link>`. No click handlers on `div` or `span`.
- Every input has a `<label htmlFor>`; icon-only buttons have `aria-label`; images have `alt`.
- Errors and async results are announced: `role="alert"` on error text, `aria-invalid` on invalid inputs, `aria-busy` or a text change on pending buttons.
- Tables use `<th scope="col">`. Dialogs trap focus and close on Escape (use the kit's dialog).

## Routes

- Each feature exports `RouteObject[]` from `routes.tsx`; `app/router.tsx` spreads them. Paths are absolute and kebab-case.
- Pages are loaded lazily: `lazy: async () => ({ Component: (await import('./pages/XPage')).XPage })`.
- Protected areas are wrapped once by a layout route in `app/` that checks the session. Pages do not check authentication themselves.
- Navigate with `<Link>` / `useNavigate()`. No `window.location` assignments.
