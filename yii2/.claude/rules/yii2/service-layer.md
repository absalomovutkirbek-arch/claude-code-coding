---
paths:
  - "**/services/**/*.php"
  - "**/dto/**/*.php"
  - "**/strategies/**/*.php"
  - "**/events/**/*.php"
  - "**/listeners/**/*.php"
  - "**/jobs/**/*.php"
  - "**/exceptions/**/*.php"
  - "**/enums/**/*.php"
---

# Yii2: service layer (services, DTOs, handlers, strategies, events)

## Service

```php
final class TransferService
{
    public function __construct(
        private readonly WalletRepositoryInterface $wallets,
        private readonly TransferRepositoryInterface $transfers,
        private readonly TransactionManagerInterface $transaction,
        private readonly EventDispatcherInterface $events,
    ) {
    }

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

- One public method per use case. Input is a DTO or scalar IDs; output is a model, a `Page`, a DTO or `void`. Never arrays, never `bool` for success.
- Method order inside a use case: load -> check rules -> change -> persist -> (after commit) dispatch.
- Business rule checks live in private `assert...()` methods that throw a module exception.
- Wrap in `$this->transaction->run()` when more than one row or table is written, or when a write depends on a prior read. Lock rows through a repository `lock...()` method when the decision depends on a mutable value.
- Dispatch events after `run()` returns. Never inside the callback.
- Forbidden in services: `Yii::$app`, `ActiveRecord::find()`, `Query`, `createCommand()`, `beginTransaction()`, request/response/session/user components, HTML or array formatting for output.
- Document every thrown domain exception with `@throws`.
- Split a service that grows past about 7 public methods or 300 lines by use-case group (`OrderService`, `OrderCancellationService`).

## DTO

```php
final class CreateTransferDto
{
    public function __construct(
        public readonly int $actorId,
        public readonly int $fromWalletId,
        public readonly int $toWalletId,
        public readonly int $amount,
    ) {
    }
}
```

- `final`, constructor-promoted `public readonly` properties, `camelCase`, fully typed, enums instead of strings.
- No methods beyond the constructor and trivial named constructors. No Yii types, no ActiveRecord instances.

## Pipeline handlers and strategies

- Use only when the trigger in `common/design-patterns.md` is met. Scaffold with `/pipeline` or `/strategy`.
- Handlers: `modules/<m>/services/handlers/<usecase>/<Step>Handler.php`, implement `app\core\pipeline\HandlerInterface`, share one `<Usecase>Context` class in the same folder.
- Strategies: `modules/<m>/strategies/<job>/`, one interface, one class per variant, one `<Job>Resolver` that maps an enum to a variant through the container.

## Exceptions

- Module exceptions live in `modules/<m>/exceptions/`, extend one of `NotFoundException`, `ForbiddenException`, `ConflictException`, `BusinessRuleException` from `app\core\exceptions` and override `errorCode()` with a specific `snake_case` code.
- The constructor takes domain values (IDs, amounts), builds the message itself and passes structured context as details.
- Use the base exceptions directly for generic cases: `throw new NotFoundException('Order not found.')`.

## Events, listeners, jobs

- Event: `final class` named in the past tense (`TransferCompleted`), readonly scalar/ID properties only. Never put ActiveRecord models into events.
- Listener: `final class` with `handle(<Event> $event): void`, registered in `config/events.php`. One reaction per listener.
- Slow or failure-prone reactions (email, SMS, external API) are pushed to the queue from the listener as a job. Jobs carry IDs, reload fresh data, and are idempotent.

## Enums

- Backed string enums in `modules/<m>/enums/`. Cases in `PascalCase`, values in `snake_case`.
- Behaviour that depends only on the enum value goes on the enum (`canTransitionTo()`, `label()`).
