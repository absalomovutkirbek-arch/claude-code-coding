# Architecture

Layered, modular monolith. Every request travels the same path, and every layer has one job.

```
HTTP entry (Controller / Action)  ->  Input validation (Form / Request)  ->  DTO
        ->  Service (use case)  ->  Repository  ->  Database
                 |-> Pipeline handlers (multi-step use cases)
                 |-> Strategy (interchangeable variants)
                 |-> Events / Jobs (side effects, after commit)
        <-  Resource (output shape)  <-
```

## Layer responsibilities

| Layer | Does | Never does |
| --- | --- | --- |
| Entry point (controller, action) | Read the request, authorize, call input validation, call exactly one service method, return a Resource | Business rules, queries, transactions, loops over domain data |
| Input validation (form, request) | Check format: required, type, length, range, enum membership. Produce a DTO | Business rules that need the database state beyond simple existence/uniqueness |
| DTO | Carry typed, immutable data between layers | Behaviour, framework types, optional "bag of anything" arrays |
| Service | Implement one use case per public method, enforce business rules, own the transaction, dispatch events | Touch HTTP request/response/session, build queries, format output |
| Repository | Every read and write to the database for one aggregate | Business decisions, transactions, HTTP awareness |
| Model / Entity | Map a table, declare relations, protect its own invariants | Queries from outside the repository, cross-aggregate logic |
| Resource | Shape the output for one API version | Queries, business logic |

## Dependency rules

- Dependencies point inward: entry point -> service -> repository interface. Never the other way.
- Inject every dependency through the constructor. Do not instantiate services or repositories with `new` and do not pull them from a global container or facade inside business code.
- Services depend on repository interfaces, not on implementations.
- A service may call another service of the same module. For another module, depend on that module's public contract (interface) only.

## Modules

- Group code by business module (order, billing, catalog), not by technical type across the whole app.
- A module owns its tables. No module reads or writes another module's tables directly. Use the owning module's service contract.
- Reference rows of other modules by ID. Do not load another module's model through relations in business code.
- Shared, business-agnostic code (transaction manager, pipeline, base exceptions, API response) lives in the shared kernel, never in a module.

## Transactions and side effects

- Open transactions only in the service layer, around one use case.
- Any use case that writes to more than one table, or reads then writes based on that read, runs inside a transaction.
- No external HTTP calls, emails, queue pushes or file uploads inside a transaction. Dispatch events or jobs after commit.
- Lock rows (`SELECT ... FOR UPDATE`) when a decision depends on a value that concurrent requests can change (stock, balance, counters).

## Where does new code go

1. Reading or writing the database -> repository.
2. A business decision or rule -> service (or a pipeline handler / strategy owned by the service).
3. Checking input shape -> form / request.
4. Reaction to something that already happened (notify, log, sync) -> event listener or job.
5. Output formatting -> resource.
6. If none fit, stop and ask before inventing a new layer.
