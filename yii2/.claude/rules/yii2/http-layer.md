---
paths:
  - "**/controllers/**/*.php"
  - "**/actions/**/*.php"
  - "**/forms/**/*.php"
  - "**/resources/**/*.php"
  - "config/routes.php"
---

# Yii2: HTTP layer (controllers, actions, forms, resources)

## Controller

```php
final class TransferController extends ApiController
{
    public function actions(): array
    {
        return [
            'create' => CreateTransferAction::class,
            'index' => ListTransfersAction::class,
            'view' => ViewTransferAction::class,
        ];
    }

    protected function verbs(): array
    {
        return ['create' => ['POST'], 'index' => ['GET'], 'view' => ['GET']];
    }
}
```

- Nothing else goes into a controller. Authentication comes from `ApiController`; list unauthenticated action IDs in `publicActions()`.
- Standard action IDs: `index`, `view`, `create`, `update`, `delete`. Custom operations use the verb: `cancel`, `approve`.

## Action

```php
final class CreateTransferAction extends ApiAction
{
    public function __construct($id, $controller, private readonly TransferService $service, array $config = [])
    {
        parent::__construct($id, $controller, $config);
    }

    public function run(): array
    {
        $form = $this->validateBody(new CreateTransferForm());

        $transfer = $this->service->create($form->toDto($this->actorId()));

        return $this->created(TransferResource::make($transfer));
    }
}
```

- `run()` has at most three steps: validate, call one service method, return through a resource. If it needs an `if`, a loop or a second service call, that logic belongs in the service.
- Body input: `validateBody()`. Query input: `validateQuery()`. Route parameters are typed `run()` arguments: `run(int $id)`.
- The authenticated user is passed into the DTO or service as `actorId`. Services never read the session.
- No `try/catch`. `ApiErrorHandler` renders every exception.
- Return helpers: `ok($data, $meta)` 200, `created($data)` 201, `paginated($page, Resource::collection(...))` 200 with pagination meta, `noContent()` 204.

## Form

- One form per endpoint that accepts input. Name: `<Verb><Entity>Form`.
- Properties are public, untyped, `snake_case` (they mirror the JSON field names) with a `@var` docblock.
- `rules()` covers format only: `required`, `integer`, `string` with `max`, `in` with enum values, `email`, `date`, `each`, and `exist` / `unique` for simple reference checks.
- Nested arrays are validated explicitly (`each` rule or a nested form). Never pass unvalidated arrays through.
- `toDto(...)` casts to the exact DTO types and converts strings to enums. It is the only way a DTO is created from HTTP input.
- A form never touches the database beyond validators, never saves, and holds no business rules.

## Resource

- Static `make(Model $model): array` and `collection(array $models): array`.
- Whitelist fields explicitly. Never call `toArray()` / `attributes` on a model.
- Format here: timestamps through `Iso8601::fromDb()`, enums as their string value, money per the project convention.
- Related data is included only when the service already loaded it. A resource never triggers a query; lazy-loading a relation inside a resource is a bug.

## Routes

- One explicit line per endpoint in `config/routes.php`: `'POST v1/billing/transfers' => 'billing/transfer/create'`.
- Constrain IDs in the pattern: `<id:\d+>`.
