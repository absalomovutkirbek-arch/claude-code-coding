---
paths:
  - "**/Repositories/**/*.php"
  - "**/Models/**/*.php"
  - "**/Migrations/**/*.php"
  - "database/migrations/**/*.php"
---

# Laravel: data layer (repositories, models, migrations)

## Repository

```php
interface TransferRepositoryInterface
{
    public function findById(int $id): ?Transfer;

    public function save(Transfer $transfer): void;

    /** @return LengthAwarePaginator<int, Transfer> */
    public function paginate(TransferFilterDto $filter): LengthAwarePaginator;
}
```

- One repository per aggregate root. Interface and implementation sit side by side in `Repositories/`; bind them in the module provider's `$bindings`.
- Method vocabulary: `findBy...` returns `?Model`, `getBy...` returns the model or throws `NotFoundException`, `listBy...` returns a `Collection`, `paginate(FilterDto)` returns `LengthAwarePaginator`, `existsBy...` returns `bool`, `lock...` loads with `lockForUpdate()`, `save`, `delete`.
- Method names describe the business question (`findActiveByCustomer`), not the SQL.
- Never return an Eloquent or query `Builder`. Never accept arbitrary condition arrays or closures from callers.
- Start queries with `Model::query()`. Use the query builder with bound parameters; raw SQL fragments never contain interpolated input.
- `save()` calls `$model->save()`. Translate `Illuminate\Database\UniqueConstraintViolationException` into `ConflictException` when the conflict is a business case.
- Eager-load what the use case needs with `->with()`. Strict mode throws on lazy loading, so a missing `with()` fails in tests.
- Row locks: `->orderBy('id')->lockForUpdate()` to avoid deadlocks. See `WalletRepository::lockByIds()` in the reference slice.
- No transactions (`DB::transaction`, `beginTransaction`), no business decisions, no `auth()` / `request()` in repositories.

## Model (Eloquent)

- `final class`, `protected $table = '<schema>.<plural_table>'`, `@property` docblock for every column with exact types, `casts()` for integers, enums, dates and JSON.
- `protected $guarded = ['id'];` and no mass assignment from input. Models are built by named constructors (`Transfer::completed(...)`) and changed by explicit assignment.
- Allowed: relations, casts, named constructors, small state methods that touch only the model's own attributes, local scopes used by the module's repository.
- Forbidden: queries in static methods, business rules, calls to services, observers or `booted()` hooks with business logic or side effects, accessors that query, global scopes that hide business rules.
- Relations to models of other modules are not declared. Use the ID and the other module's service contract.

## Migrations

- Inside the module: `app/Modules/<Module>/Database/Migrations/`, loaded by the module provider with `loadMigrationsFrom()`. Create with `php artisan make:migration <name> --path=app/Modules/<Module>/Database/Migrations`.
- Anonymous class with `up()` and a real `down()` that reverts in reverse order. If it cannot revert, throw an exception with the reason.
- The first migration of a module creates its schema: `DB::statement('CREATE SCHEMA IF NOT EXISTS <schema>')`. The schema is also added to `search_path` in `config/database.php`; without it `migrate:fresh` and `RefreshDatabase` do not drop the module's tables.
- Always write the schema-qualified table name: `Schema::create('billing.transfers', ...)`.
- Types: `id()`, `unsignedBigInteger()` for references, `timestampsTz()`, `string('status', 32)` plus a `CHECK` constraint (through `DB::statement`) for enums, `bigInteger()` minor units or `decimal(19, 4)` for money.
- Every foreign key is declared with an explicit name and delete rule and has an index. Constraint names follow `common/database.md`.
- Never reference application classes (models, enums, services) in a migration. Write literal values.
- Never edit a migration that is already committed. Add a new one. A hook blocks such edits.
- Applying or reverting migrations (`php artisan migrate`, `migrate:rollback`) requires the developer's confirmation. `migrate:fresh`, `migrate:reset` and `db:wipe` are denied.
