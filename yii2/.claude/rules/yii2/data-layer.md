---
paths:
  - "**/repositories/**/*.php"
  - "**/models/**/*.php"
  - "**/migrations/**/*.php"
---

# Yii2: data layer (repositories, models, migrations)

## Repository

```php
interface TransferRepositoryInterface
{
    public function findById(int $id): ?Transfer;

    public function save(Transfer $transfer): void;

    /** @return Page<Transfer> */
    public function paginate(TransferFilterDto $filter): Page;
}
```

- One repository per aggregate root. Interface and implementation sit side by side in `repositories/`; bind them in `config/container.php`.
- Method vocabulary: `findBy...` returns `?Model`, `getBy...` returns the model or throws `NotFoundException`, `listBy...` returns an array, `paginate(FilterDto)` returns `Page`, `existsBy...` returns `bool`, `lock...` loads with `FOR UPDATE`, `save`, `delete`.
- Method names describe the business question (`findActiveByCustomer`), not the SQL.
- Never return `ActiveQuery`, `Query`, `ActiveDataProvider` or raw rows. Never accept arbitrary condition arrays from callers.
- `save()` calls `$model->save(false)` and throws `RuntimeException` on `false`. Translate unique-constraint `yii\db\IntegrityException` into `ConflictException` when the conflict is a business case.
- Eager-load what the use case needs with `->with()`. Collections never trigger per-row queries.
- Row locks: build the query, append `FOR UPDATE`, order by ID to avoid deadlocks. See `WalletRepository::lockByIds()` in the reference slice.
- No transactions, no business decisions, no `Yii::$app->user` / request in repositories.

## Model (ActiveRecord)

- `final class`, `tableName()` with the module schema (`billing.transfer`), `@property` docblock for every column with exact types.
- Allowed: relations (`getItems(): ActiveQuery`), `behaviors()` with `UtcTimestampBehavior`, named constructors (`Transfer::completed(...)`), enum accessors (`statusEnum()`), small state methods that touch only the model's own attributes.
- Forbidden: `rules()`, `load()` from request data, static finder methods, queries, calls to services, `beforeSave`/`afterSave` hooks that contain business logic or side effects.
- Relations to models of other modules are not declared. Use the ID and the other module's service contract.

## Migrations

- Namespaced, inside the module: `modules/<m>/migrations/M<YYMMDDHHMMSS><Name>.php`. Create with `php yii migrate/create 'app\modules\<m>\migrations\<Name>'`.
- Use `safeUp()` / `safeDown()`. `safeDown()` must really revert, in reverse order. If it cannot, throw an exception with the reason.
- The first migration of a module creates its schema: `CREATE SCHEMA IF NOT EXISTS <module>`.
- Types: `bigPrimaryKey()`, `bigInteger()` for references, `timestamptz NOT NULL DEFAULT NOW()` for `created_at` / `updated_at`, `string(32)` plus a `CHECK` constraint for enums, `bigInteger()` minor units or `decimal(19,4)` for money.
- Every foreign key is declared with an explicit delete rule and has an index. Constraint names follow `common/database.md`.
- Never reference application classes (models, enums, services) in a migration. Write literal values.
- Never edit a migration that is already committed. Add a new one. A hook blocks such edits.
- Applying or reverting migrations (`php yii migrate`, `migrate/down`) requires the developer's confirmation.
