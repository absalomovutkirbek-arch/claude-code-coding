---
name: new-endpoint
description: Build one API endpoint as a full vertical slice - migration, entity, repository, DTO, service method, request record, controller method, response record and tests. Use for any new endpoint or use case in a Spring Boot module.
argument-hint: "[module] [VERB /path] [what it does]"
---

# New endpoint (vertical slice)

Build the endpoint `$ARGUMENTS`.

The canonical, tested example of every file is in `${CLAUDE_SKILL_DIR}/reference/` (module `billing`, resource `transfers`). Read the matching reference file before writing each class and keep the same shape. The files end in `.tpl` only so IDEs do not index them.

## 1. Clarify the business side

Before writing code, state in a few lines and confirm anything unclear with the developer:

- Who may call the endpoint, and on which records (ownership)?
- Input fields with types and limits.
- Business rules that can reject the request, and the error code for each.
- What changes in the database; which tables.
- Side effects after success (notifications, events, jobs).
- What the response contains.

Do not invent business rules. Technical structure is decided by the project rules, not by the developer.

## 2. Decide the shape

- Writes to more than one row or table, or a write that depends on a read -> `@Transactional` on the service method, plus row locks if the decision depends on a mutable value.
- 3 or more ordered steps -> `/pipeline`. 2 or more interchangeable variants -> `/strategy`. Otherwise a plain service method.
- New tables or columns -> `/new-migration` first.

## 3. Build in this order

Java paths are under `reference/src/main/java/com/example/app/modules/billing/`.

| # | File | Reference |
| --- | --- | --- |
| 1 | Migration (if the schema changes) | `reference/src/main/resources/db/migration/billing/` |
| 2 | Enum for any status/type | `enums/TransferStatus.java.tpl` |
| 3 | Entity: mapping only | `entity/Transfer.java.tpl`, `Wallet.java.tpl` |
| 4 | Repository | `repository/TransferRepository.java.tpl`, `WalletRepository.java.tpl` (row locking) |
| 5 | Module exceptions, one per rejecting rule | `exception/InsufficientBalanceException.java.tpl` |
| 6 | DTO record | `dto/CreateTransferDto.java.tpl`, `TransferFilterDto.java.tpl` |
| 7 | Service method | `service/TransferService.java.tpl` |
| 8 | Event + listener (if there are side effects) | `event/`, `listener/` |
| 9 | Request record with validation and `toDto()` | `request/CreateTransferRequest.java.tpl`, `ListTransfersRequest.java.tpl` |
| 10 | Response record | `response/TransferResponse.java.tpl` |
| 11 | Controller method | `controller/TransferController.java.tpl` (create, view, list) |
| 12 | Unit test of the service method | `reference/src/test/.../service/TransferServiceTest.java.tpl` |
| 13 | API test of the endpoint | `reference/src/test/.../controller/TransferApiTest.java.tpl` |

Reuse existing classes of the module (entity, repository, service, response, controller) and add methods to them. Create a new class only when none fits.

## 4. Endpoint conventions

| Operation | Mapping | Controller method | Service method | Success |
| --- | --- | --- | --- | --- |
| List | `@GetMapping` | `list` | `list(FilterDto): Page` | 200 `ApiResponse.page()` |
| View | `@GetMapping("/{id:\\d+}")` | `view` | `get...(id, actorId)` | 200 `ApiResponse.of()` |
| Create | `@PostMapping` | `create` | `create(Dto)` | 201 `@ResponseStatus(CREATED)` |
| Update | `@PutMapping` / `@PatchMapping("/{id:\\d+}")` | `update` | `update(id, Dto)` | 200 |
| Delete | `@DeleteMapping("/{id:\\d+}")` | `delete` | `delete(id, actorId)` | 204 `@ResponseStatus(NO_CONTENT)`, `void` |
| Operation | `@PostMapping("/{id:\\d+}/<verb>")` | `<verb>` | `<verb>(id, ...)` | 200 |

A record that exists but belongs to someone else is reported as `NotFoundException` when its existence must stay hidden, otherwise `ForbiddenException`.

## 5. Verify and report

1. Compile, then run the new tests and the module's tests: `./mvnw test -Dtest='<Entity>ServiceTest,<Entity>ApiTest'` (or the Gradle equivalent from "Project facts").
2. The API test boots the whole context, so it also proves that the migration and the entity mapping agree.
3. Re-read the diff with the checklist in `/arch-review`.
4. Report: endpoint and example request/response, files by layer, schema changes, business rules implemented with their error codes, assumptions, test results. Remind the developer that the migration runs on the next application start in each environment.
