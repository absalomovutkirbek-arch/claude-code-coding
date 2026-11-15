# Validation and error handling

## Two levels of validation

1. **Input validation** at the entry point (form / request class): presence, type, length, range, format, enum membership, simple existence or uniqueness. Failure returns 422 with `validation_failed` and per-field details. The service is never called.
2. **Business rules** in the service: anything that depends on state or on several values together ("stock is sufficient", "order can be cancelled only while pending", "user owns this resource"). Failure throws a domain exception.

The service never trusts that it is called only from HTTP. It re-checks every business rule, but does not repeat format checks: the DTO type already guarantees them.

## Domain exceptions

One small hierarchy, shared by all modules:

| Exception | Meaning | HTTP |
| --- | --- | --- |
| `ValidationException` | Input shape is wrong | 422 |
| `NotFoundException` | The resource does not exist or is not visible to the caller | 404 |
| `ForbiddenException` | The caller is not allowed to do this | 403 |
| `ConflictException` | Duplicate or concurrent modification | 409 |
| `BusinessRuleException` | A business rule rejected the operation | 422 |

- Module-specific exceptions extend one of these and carry a stable `snake_case` error code: `InsufficientStockException` -> `insufficient_stock`.
- Exception messages are written for the API consumer. Internal context goes into structured properties and logs.
- Domain exceptions know nothing about HTTP. The mapping to status codes lives in exactly one place (the global error handler).

## Rules

- Throw exceptions for failures. Do not return `false`, `null`, error arrays or status flags.
- Catch an exception only if you can do something meaningful: translate it (infrastructure -> domain), compensate, or retry. Otherwise let it propagate.
- Never swallow: no empty `catch`, no catch-log-continue that hides a failed operation.
- Catch the narrowest type. Catching the base `Exception`/`Throwable` is allowed only at the outer boundary (global handler, job runner, pipeline compensation).
- Translate infrastructure exceptions at the boundary: a unique-constraint violation becomes `ConflictException` in the repository; an HTTP client failure becomes a module-specific gateway exception in the adapter.
- Unexpected exceptions become a 500 with code `internal_error` and a generic message. Details go to the log, not to the client.
- Entry points do not contain `try/catch` for domain exceptions. The global handler renders them.

## Logging

- Log unexpected exceptions once, at the boundary, with context (request ID, user ID, entity IDs).
- Expected domain exceptions (validation, not found, business rule) are not errors. Log them at info/notice at most.
- Never log passwords, tokens, card data, full personal documents or raw request bodies of auth endpoints.
- Use structured context (`['order_id' => $id]`), not string concatenation.
