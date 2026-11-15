---
paths:
  - "src/**/api/**/*.ts"
  - "src/**/hooks/**/*.ts"
  - "src/**/model/**/*.ts"
  - "src/shared/api/**/*.ts"
---

# React: data layer (models, API modules, query hooks)

## Model

```ts
export const TransferStatus = {
  Completed: 'completed',
  Reversed: 'reversed',
} as const;

export type TransferStatus = (typeof TransferStatus)[keyof typeof TransferStatus];

export interface Transfer {
  id: number;
  fromWalletId: number;
  /** Minor units. */
  amount: number;
  status: TransferStatus;
  /** ISO 8601, UTC. */
  createdAt: string;
}
```

- camelCase fields. Enum values are exactly the lowercase strings the API sends.
- Money stays an integer in minor units and timestamps stay ISO strings in the model. They are formatted in components with `shared/lib`.
- Input types of mutations (`CreateTransferInput`) and filter types (`TransferFilter`) live here too.

## API module (the repository of the frontend)

```ts
interface TransferDto { id: number; from_wallet_id: number; /* ... */ }

function toTransfer(dto: TransferDto): Transfer { /* field by field */ }

export async function listTransfers(filter: TransferFilter): Promise<Page<Transfer>> {
  const response = await http.get<TransferDto[], PageMetaDto>(URL, { page: filter.page, per_page: filter.perPage });

  return toPage(response, toTransfer);
}
```

- One file per backend resource: `api/<resource>.api.ts`. It is the only place that knows URLs, wire field names and the envelope.
- Wire types end in `Dto`, are declared in the API module and are not exported. Mapping is explicit, field by field, in both directions. No generic "snake to camel" converters: the mapping is the contract.
- Functions take and return models: `list...(filter): Promise<Page<T>>`, `get...(id): Promise<T>`, `create...(input): Promise<T>`, `update...(id, input)`, `delete...(id): Promise<void>`.
- No `try/catch`: `http` already rejects with `ApiError`. No React, no hooks, no toasts here.
- Build paths with template strings from validated IDs. Query values go through the `params` argument, never into the URL by hand.
- The base URL and the token are the business of `shared/api/http.ts`. Do not create another axios instance or call `fetch`.

## Query hooks (the service of the frontend)

```ts
export const transferKeys = {
  all: ['billing', 'transfers'] as const,
  lists: () => [...transferKeys.all, 'list'] as const,
  list: (filter: TransferFilter) => [...transferKeys.lists(), filter] as const,
  detail: (id: number) => [...transferKeys.all, 'detail', id] as const,
};

export function useCreateTransfer() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createTransfer,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: transferKeys.lists() }),
  });
}
```

- One hook per file, wrapping exactly one `useQuery` or `useMutation`. Name: `use<Entity>`, `use<Entities>`, `use<Verb><Entity>`.
- Query keys come only from the resource's key factory. Never write a key array inline.
- Everything the query depends on is in its key (the whole filter object).
- A mutation invalidates the lists and details it changes in its own `onSuccess`. Components do not invalidate.
- Paginated lists use `placeholderData: keepPreviousData`. Queries that need an ID use `enabled` when the ID can be missing.
- Hooks return the query or mutation object as is. Do not wrap it in a custom shape and do not copy `data` into state.
- Per-call reactions (close a dialog, navigate, show form errors) are passed by the component: `mutation.mutate(input, { onSuccess, onError })`.
- Retry and stale-time defaults live in `shared/api/queryClient.ts`. Override per hook only with a stated reason.
- Optimistic updates only when the developer asks for them; they need `onMutate` + rollback in `onError`.

## Errors

- Every failure is an `ApiError` with `status`, `code`, `details`. Decide by `code`: `validation_failed`, `unauthorized`, `forbidden`, `not_found`, `conflict`, the module's business codes, and the client-side `network_error` / `http_error`.
- 401 is handled once, by the handler registered with `setUnauthorizedHandler()` in the app shell.
- User text for a code comes from the feature's `errors.ts`; an unknown code falls back to the API message.
