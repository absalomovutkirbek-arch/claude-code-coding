---
paths:
  - "**/service/**/*.java"
  - "**/dto/**/*.java"
  - "**/strategy/**/*.java"
  - "**/event/**/*.java"
  - "**/listener/**/*.java"
  - "**/exception/**/*.java"
  - "**/enums/**/*.java"
---

# Spring Boot: service layer (services, DTOs, handlers, strategies, events)

## Service

```java
@Service
public class TransferService {

    private final WalletRepository wallets;
    private final TransferRepository transfers;
    private final ApplicationEventPublisher events;

    // constructor

    @Transactional
    public Transfer create(CreateTransferDto dto) {
        // 1. load (and lock) through repositories
        // 2. assert business rules, throw domain exceptions
        // 3. change state, save through repositories
        events.publishEvent(new TransferCompleted(transfer.getId()));

        return transfer;
    }
}
```

- One public method per use case. Input is a DTO record or scalar IDs; output is an entity, a `Page`, a DTO or `void`. Never `Map`, never `boolean` for success, never `ResponseEntity`.
- Method order inside a use case: load -> check rules -> change -> persist -> publish event.
- Business rule checks live in private `assert...()` methods that throw a module exception.
- `@Transactional` goes on the public use-case method that writes more than one row or decides on data it read. Read-only use cases use `@Transactional(readOnly = true)`. Never on the class, on private methods, on controllers or on repositories.
- A `@Transactional` method called from another method of the same class does not start a transaction (no proxy). Keep one transactional entry point per use case.
- Lock rows through a repository `lock...()` method when the decision depends on a mutable value.
- Call `repository.save()` explicitly for every changed entity. Do not rely on dirty checking alone; the explicit call keeps the write visible and unit-testable.
- No external calls (HTTP, email, queue) inside a transaction. Publish an event and react after commit.
- Forbidden in services: `EntityManager`, `JdbcTemplate`, `HttpServletRequest`, `SecurityContextHolder`, `ResponseEntity`, request and response records, `@Autowired` fields.
- Document every thrown domain exception with `@throws`.
- Split a service that grows past about 7 public methods or 300 lines by use-case group (`OrderService`, `OrderCancellationService`).

## DTO

```java
public record CreateTransferDto(long actorId, long fromWalletId, long toWalletId, long amount) {
}
```

- A record: immutable, fully typed, primitives for required values, enums instead of strings.
- No behaviour beyond a compact constructor that normalises values. No entities, no request records, no Spring types.

## Pipeline handlers and strategies

- Use only when the trigger in `common/design-patterns.md` is met. Scaffold with `/pipeline` or `/strategy`.
- Handlers: `service/handler/<usecase>/<Step>Handler`, `@Component` classes implementing `Handler<<Usecase>Context>` from `<base>.core.pipeline`, sharing one `<Usecase>Context` class in the same package.
- Strategies: `strategy/<job>/`, one interface, one `@Component` per variant, one `<Job>Resolver` that maps an enum to a variant and fails at startup when a case has no variant.

## Exceptions

- Module exceptions live in `exception/`, extend one of `NotFoundException`, `ForbiddenException`, `ConflictException`, `BusinessRuleException` from `<base>.core.exception` and override `errorCode()` with a specific `snake_case` code.
- The constructor takes domain values (IDs, amounts), builds the message itself and passes structured context as details with `snake_case` keys.
- Use the base exceptions directly for generic cases: `throw new NotFoundException("Order not found.")`.
- Do not throw `ResponseStatusException`, `EntityNotFoundException` or `IllegalArgumentException` for business failures. They bypass the error codes. Checked exceptions are not used for business failures.

## Events and listeners

- Event: a record named in the past tense (`TransferCompleted`) with IDs and scalars only. Never put entities into events.
- Publish with `ApplicationEventPublisher.publishEvent()` inside the transactional method.
- Listener: `@Component` with `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)`. One reaction per listener. It reloads fresh data by ID.
- Slow or failure-prone reactions (email, SMS, external API) add `@Async`, or hand over to the project's queue. They are idempotent.
- A listener that writes to the database needs its own transaction: `@Transactional(propagation = Propagation.REQUIRES_NEW)`.

## Enums

- `enums/` package, constants in `UPPER_SNAKE_CASE`, a `@JsonValue value()` method returning the lowercase name.
- Behaviour that depends only on the enum value goes on the enum (`canTransitionTo()`).
