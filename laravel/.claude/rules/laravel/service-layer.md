---
paths:
  - "**/Services/**/*.php"
  - "**/Dto/**/*.php"
  - "**/Strategies/**/*.php"
  - "**/Events/**/*.php"
  - "**/Listeners/**/*.php"
  - "**/Jobs/**/*.php"
  - "**/Exceptions/**/*.php"
  - "**/Enums/**/*.php"
---

# Laravel: service layer (services, DTOs, handlers, strategies, events)

## Service

```php
final class TransferService
{
    public function __construct(
        private readonly WalletRepositoryInterface $wallets,
        private readonly TransferRepositoryInterface $transfers,
        private readonly TransactionManagerInterface $transaction,
        private readonly Dispatcher $events,
    ) {}

    public function create(CreateTransferDto $dto): Transfer
    {
        $transfer = $this->transaction->run(function () use ($dto): Transfer {
            // 1. load (and lock) through repositories
            // 2. assert business rules, throw domain exceptions
            // 3. change state, save through repositories
            return $transfer;
        });

        $this->events->dispatch(new TransferCompleted($transfer->id));

        return $transfer;
    }
}
```

- One public method per use case. Input is a DTO or scalar IDs; output is a model, a paginator, a DTO or `void`. Never arrays, never `bool` for success.
- Method order inside a use case: load -> check rules -> change -> persist -> (after commit) dispatch.
- Business rule checks live in private `assert...()` methods that throw a module exception.
- Wrap in `$this->transaction->run()` when more than one row or table is written, or when a write depends on a prior read. Lock rows through a repository `lock...()` method when the decision depends on a mutable value.
- Dispatch events after `run()` returns. Never inside the callback.
- Forbidden in services: facades (`DB::`, `Auth::`, `Event::`, `Cache::`), `app()`, `resolve()`, `request()`, `auth()`, `session()`, Eloquent queries (`Model::query()`, `::where()`, `::find()`), `$model->save()` / `->delete()` / `->update([...])`, array or JSON formatting for output.
- Document every thrown domain exception with `@throws`.
- Split a service that grows past about 7 public methods or 300 lines by use-case group (`OrderService`, `OrderCancellationService`).

## DTO

```php
final readonly class CreateTransferDto
{
    public function __construct(
        public int $actorId,
        public int $fromWalletId,
        public int $toWalletId,
        public int $amount,
    ) {}
}
```

- `final readonly class`, constructor-promoted public properties, `camelCase`, fully typed, enums instead of strings.
- No methods beyond the constructor and trivial named constructors. No Request, no Eloquent models, no Collections of models.

## Pipeline handlers and strategies

- Use only when the trigger in `common/design-patterns.md` is met. Scaffold with `/pipeline` or `/strategy`.
- Handlers: `Services/Handlers/<Usecase>/<Step>Handler.php`, implement `App\Core\Pipeline\HandlerInterface`, share one `<Usecase>Context` class in the same folder, and are run by `Illuminate\Pipeline\Pipeline`.
- Strategies: `Strategies/<Job>/`, one interface, one class per variant, one `<Job>Resolver` that maps an enum to a variant.

## Exceptions

- Module exceptions live in `Exceptions/`, extend one of `NotFoundException`, `ForbiddenException`, `ConflictException`, `BusinessRuleException` from `App\Core\Exceptions` and override `errorCode()` with a specific `snake_case` code.
- The constructor takes domain values (IDs, amounts), builds the message itself and passes structured context as details.
- Use the base exceptions directly for generic cases: `throw new NotFoundException('Order not found.')`.
- Do not throw `abort()`, `HttpException` or `ModelNotFoundException` (`findOrFail`) from services or repositories. They bypass the error codes.

## Events, listeners, jobs

- Event: `final readonly class` named in the past tense (`TransferCompleted`), scalar/ID properties only, implements `ShouldDispatchAfterCommit`. Never put Eloquent models into events (no `SerializesModels`).
- Listener: `final class` with `handle(<Event> $event): void`, registered in the module provider. One reaction per listener.
- Slow or failure-prone reactions (email, SMS, external API) run on the queue: the listener implements `ShouldQueue`, or dispatches a job. Jobs carry IDs, reload fresh data, and are idempotent.

## Enums

- Backed string enums in `Enums/`. Cases in `PascalCase`, values in `snake_case`.
- Behaviour that depends only on the enum value goes on the enum (`canTransitionTo()`, `label()`).
