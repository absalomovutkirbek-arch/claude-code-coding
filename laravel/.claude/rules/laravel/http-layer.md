---
paths:
  - "**/Http/**/*.php"
  - "**/routes/*.php"
  - "routes/*.php"
---

# Laravel: HTTP layer (routes, actions, form requests, resources)

## Routes

```php
// app/Modules/Billing/routes/api.php. Prefix api/v1/billing and middleware come from BillingServiceProvider.
Route::post('transfers', CreateTransferAction::class);
Route::get('transfers', ListTransfersAction::class);
Route::get('transfers/{id}', ViewTransferAction::class)->whereNumber('id');
```

- One explicit line per endpoint, pointing at an Action class. Constrain IDs with `whereNumber()`.
- No closures with logic, no `Route::resource()` / `apiResource()`.
- Public (unauthenticated) endpoints are declared in a separate group in the module provider without `auth:sanctum`.

## Action

```php
final class CreateTransferAction
{
    public function __construct(private readonly TransferService $service) {}

    public function __invoke(CreateTransferRequest $request): JsonResponse
    {
        $transfer = $this->service->create($request->toDto());

        return ApiResponse::created(TransferResource::make($transfer));
    }
}
```

- `__invoke()` has at most three steps: receive the validated request, call one service method, return through a resource. If it needs an `if`, a loop or a second service call, that logic belongs in the service.
- Input always arrives as a FormRequest. Route parameters are typed scalar arguments: `__invoke(Request $request, int $id)`.
- An action without input still passes the authenticated user explicitly: `(int) $request->user()->getAuthIdentifier()`. Services never read the session or the request.
- No `try/catch`. `ApiExceptionRenderer` renders every exception.
- Return helpers: `ApiResponse::ok($data, $meta)` 200, `created($data)` 201, `paginated($paginator, Resource::class)` 200 with pagination meta, `noContent()` 204. Never `response()->json()` and never return a model or a resource directly.

## FormRequest

- One request class per endpoint that accepts input. Name: `<Verb><Entity>Request`.
- `rules()` covers format only: `required`, `integer`, `string` with `max`, `Rule::enum()`, `email`, `date`, array rules with `*`, and `exists` / `unique` for simple reference checks.
- Nested arrays are validated explicitly (`items.*.product_id`). Never pass unvalidated arrays through.
- `toDto()` casts to the exact DTO types with `$this->integer()`, `$this->string()->toString()`, `$this->boolean()`, `$this->enum()`, `$this->date()`. It is the only way a DTO is created from HTTP input, and it reads the actor from `$this->user()`.
- `authorize()` may check a role or permission through a gate. It never queries records; record-level ownership is a business rule and lives in the service.
- A request never saves and holds no business rules.

## Resource

- `final class extends JsonResource` with `@mixin <Model>` and an explicit `toArray()` whitelist. Never `parent::toArray()` and never `$model->toArray()`.
- Format here: timestamps as UTC ISO 8601 (`->utc()->format('Y-m-d\TH:i:s\Z')`), enums as their string value, money per the project convention.
- Related data is included with `$this->whenLoaded()` only. A resource never triggers a query; strict mode throws on lazy loading.
- Resources are passed to `ApiResponse`, which builds the `{data, meta}` envelope. Do not rely on `JsonResource::wrap()` or resource collections for the envelope.

## Errors

- Validation failures are rendered as 422 `validation_failed` with field messages in `error.details`.
- A missing route, wrong verb or unauthenticated request already produces the standard error envelope. Do not add per-endpoint handling.
