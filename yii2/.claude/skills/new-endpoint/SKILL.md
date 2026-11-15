---
name: new-endpoint
description: Build one API endpoint as a full vertical slice - migration, model, repository, DTO, service method, form, action, resource, route, DI binding and tests. Use for any new endpoint or use case in a Yii2 module.
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

- Writes to more than one table, or a write that depends on a read -> transaction in the service, plus row locks if the decision depends on a mutable value.
- 3 or more ordered steps -> `/pipeline`. 2 or more interchangeable variants -> `/strategy`. Otherwise a plain service method.
- New tables or columns -> `/new-migration` first.

## 3. Build in this order

| # | File | Reference |
| --- | --- | --- |
| 1 | Migration (if the schema changes) | `reference/modules/billing/migrations/` |
| 2 | Enum for any status/type | `enums/TransferStatus.php.tpl` |
| 3 | Model: mapping only | `models/Transfer.php.tpl` |
| 4 | Repository interface + implementation | `repositories/Transfer*.tpl`, `Wallet*.tpl` (row locking) |
| 5 | Module exceptions, one per rejecting rule | `exceptions/InsufficientBalanceException.php.tpl` |
| 6 | DTO | `dto/CreateTransferDto.php.tpl`, `TransferFilterDto.php.tpl` |
| 7 | Service method | `services/TransferService.php.tpl` |
| 8 | Event + listener (if there are side effects) | `events/`, `listeners/` |
| 9 | Form with `rules()` and `toDto()` | `forms/CreateTransferForm.php.tpl`, `ListTransfersForm.php.tpl` |
| 10 | Resource | `resources/TransferResource.php.tpl` |
| 11 | Action | `actions/transfer/*.tpl` (create, view, list) |
| 12 | Controller: add to `actions()` and `verbs()` | `controllers/TransferController.php.tpl` |
| 13 | Unit test of the service method | `reference/tests/unit/modules/billing/TransferServiceTest.php.tpl` |

Reuse existing classes of the module (model, repository, service, resource) and add methods to them. Create a new class only when none fits.

## 4. Wire

- `config/routes.php`: `'<VERB> v1/<resource>' => '<module>/<controller>/<action>'`, with `<id:\d+>` for IDs.
- `config/container.php`: bind every new repository interface to its implementation.
- `config/events.php`: register new listeners.

## 5. Endpoint conventions

| Operation | Route | Action | Service method | Success |
| --- | --- | --- | --- | --- |
| List | `GET v1/<resources>` | `List<Entities>Action` | `list(FilterDto): Page` | 200 `paginated()` |
| View | `GET v1/<resources>/<id>` | `View<Entity>Action` | `get...(id, actorId)` | 200 `ok()` |
| Create | `POST v1/<resources>` | `Create<Entity>Action` | `create(Dto)` | 201 `created()` |
| Update | `PUT`/`PATCH v1/<resources>/<id>` | `Update<Entity>Action` | `update(id, Dto)` | 200 `ok()` |
| Delete | `DELETE v1/<resources>/<id>` | `Delete<Entity>Action` | `delete(id, actorId)` | 204 `noContent()` |
| Operation | `POST v1/<resources>/<id>/<verb>` | `<Verb><Entity>Action` | `<verb>(id, ...)` | 200 `ok()` |

A record that exists but belongs to someone else is reported as `NotFoundException` when its existence must stay hidden, otherwise `ForbiddenException`.

## 6. Verify and report

1. `php -l` on new files; run static analysis and the code style fixer if the project has them.
2. Run the new unit tests and the module's suite.
3. Re-read the diff with the checklist in `/arch-review`.
4. Report: endpoint and example request/response, files by layer, schema changes, business rules implemented with their error codes, assumptions, test results. Remind the developer to apply the migration; do not apply it yourself without confirmation.
