---
name: new-endpoint
description: Build one API endpoint as a full vertical slice - migration, model, repository, DTO, service method, form request, action, resource, route, container binding and tests. Use for any new endpoint or use case in a Laravel module.
argument-hint: "[Module] [VERB /path] [what it does]"
---

# New endpoint (vertical slice)

Build the endpoint `$ARGUMENTS`.

The canonical, tested example of every file is in `${CLAUDE_SKILL_DIR}/reference/` (module `Billing`, resource `transfers`). Read the matching reference file before writing each class and keep the same shape. The files end in `.tpl` only so IDEs do not index them.

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

All paths are under `reference/app/Modules/Billing/`.

| # | File | Reference |
| --- | --- | --- |
| 1 | Migration (if the schema changes) | `Database/Migrations/` |
| 2 | Enum for any status/type | `Enums/TransferStatus.php.tpl` |
| 3 | Model: mapping only | `Models/Transfer.php.tpl` |
| 4 | Repository interface + implementation | `Repositories/Transfer*.tpl`, `Wallet*.tpl` (row locking) |
| 5 | Module exceptions, one per rejecting rule | `Exceptions/InsufficientBalanceException.php.tpl` |
| 6 | DTO | `Dto/CreateTransferDto.php.tpl`, `TransferFilterDto.php.tpl` |
| 7 | Service method | `Services/TransferService.php.tpl` |
| 8 | Event + listener (if there are side effects) | `Events/`, `Listeners/` |
| 9 | FormRequest with `rules()` and `toDto()` | `Http/Requests/CreateTransferRequest.php.tpl`, `ListTransfersRequest.php.tpl` |
| 10 | Resource | `Http/Resources/TransferResource.php.tpl` |
| 11 | Action | `Http/Actions/Transfer/*.tpl` (create, view, list) |
| 12 | Unit test of the service method | `reference/tests/Unit/Modules/Billing/TransferServiceTest.php.tpl` |
| 13 | Feature test of the endpoint | `reference/tests/Feature/Modules/Billing/TransferApiTest.php.tpl` |

Reuse existing classes of the module (model, repository, service, resource) and add methods to them. Create a new class only when none fits.

## 4. Wire

All in the module (`routes/api.php` and `Providers/<Module>ServiceProvider.php`):

- Route: `Route::<verb>('<resources>', <Action>::class);` with `->whereNumber('id')` for IDs.
- `$bindings`: every new repository interface => implementation.
- `boot()`: `Event::listen(<Event>::class, <Listener>::class)` for new listeners.

## 5. Endpoint conventions

| Operation | Route | Action | Service method | Success |
| --- | --- | --- | --- | --- |
| List | `GET <resources>` | `List<Entities>Action` | `list(FilterDto): LengthAwarePaginator` | 200 `paginated()` |
| View | `GET <resources>/{id}` | `View<Entity>Action` | `get...(id, actorId)` | 200 `ok()` |
| Create | `POST <resources>` | `Create<Entity>Action` | `create(Dto)` | 201 `created()` |
| Update | `PUT`/`PATCH <resources>/{id}` | `Update<Entity>Action` | `update(id, Dto)` | 200 `ok()` |
| Delete | `DELETE <resources>/{id}` | `Delete<Entity>Action` | `delete(id, actorId)` | 204 `noContent()` |
| Operation | `POST <resources>/{id}/<verb>` | `<Verb><Entity>Action` | `<verb>(id, ...)` | 200 `ok()` |

A record that exists but belongs to someone else is reported as `NotFoundException` when its existence must stay hidden, otherwise `ForbiddenException`.

## 6. Verify and report

1. `vendor/bin/pint` on the new files; run static analysis if the project has it.
2. Run the new tests and the module's suite: `php artisan test --filter=<Module>` or by path.
3. `php artisan route:list --path=api/v1/<module>` shows the new route.
4. Re-read the diff with the checklist in `/arch-review`.
5. Report: endpoint and example request/response, files by layer, schema changes, business rules implemented with their error codes, assumptions, test results. Remind the developer to apply the migration; do not apply it yourself without confirmation.
