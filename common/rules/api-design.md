# API design

## URLs and methods

- Resources are plural nouns in kebab-case: `/api/v1/orders`, `/api/v1/order-items`.
- Version in the path: `/api/v1/...`. A breaking change means a new version, never a silent change.
- `GET` reads, `POST` creates, `PUT`/`PATCH` updates, `DELETE` deletes. `GET` never changes state.
- Non-CRUD operations are sub-resources named by the action: `POST /orders/{id}/cancel`.
- Nest at most one level: `/orders/{id}/items`. Deeper relations use filters.
- JSON fields use one casing across the whole API. Default: `snake_case`. If the existing project uses another, keep it.

## Status codes

| Code | When |
| --- | --- |
| 200 | Successful read or update with a body |
| 201 | Resource created. Body contains the resource |
| 204 | Success with no body (delete) |
| 400 | Malformed request (unparseable JSON, wrong content type) |
| 401 | Not authenticated |
| 403 | Authenticated but not allowed |
| 404 | Resource does not exist or is not visible to the caller |
| 409 | Conflict with current state (duplicate, concurrent modification) |
| 422 | Validation failed or a business rule rejected the request |
| 429 | Rate limit exceeded |
| 500 | Unexpected error. Never used for expected outcomes |

## Response envelope

Success:

```json
{
  "data": { "id": 15, "status": "paid" },
  "meta": {}
}
```

Collections always paginate:

```json
{
  "data": [ { "id": 15 }, { "id": 16 } ],
  "meta": { "page": 1, "per_page": 20, "total": 134, "total_pages": 7 }
}
```

Error:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "The given data is invalid.",
    "details": { "email": ["Email is not a valid email address."] }
  }
}
```

- `error.code` is a stable machine-readable `snake_case` string. Clients branch on it, never on `message`.
- `error.message` is safe to show to a user. No stack traces, SQL, class names or internal IDs outside debug mode.
- `error.details` holds field errors for validation, otherwise it is omitted or holds structured context.

## Collections

- Every list endpoint paginates. Default `per_page` 20, maximum 100.
- Filtering through explicit query parameters (`?status=paid&created_from=2026-01-01`). Sorting through `?sort=-created_at` with a whitelist of sortable fields.
- Never expose "return everything" endpoints.

## Data

- Dates and times in ISO 8601 UTC: `2026-01-31T09:30:00Z`.
- Money is never a JSON float. Use one convention per project: integer minor units (`"amount": 15000000`) or a decimal string (`"amount": "150000.00"`), always next to a `currency` field.
- IDs are opaque to the client. Enums are lowercase strings, not integers.
- Output goes through a Resource. Never serialize a database model directly; never leak internal columns (password hashes, tokens, soft-delete flags).

## Safety

- Creation endpoints that charge money or trigger irreversible effects accept an `Idempotency-Key` header and return the first result on retry.
- Authorization is checked on every endpoint, including "read-only" ones.
