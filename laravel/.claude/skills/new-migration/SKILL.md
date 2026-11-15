---
name: new-migration
description: Create a database migration for a module following the schema, naming, constraint and index rules. Use for any table, column, index or constraint change.
argument-hint: "[Module] [what changes]"
---

# New migration

Create a migration for `$ARGUMENTS`.

## 1. Design before writing

Write the table design in the chat first and check it against `.claude/rules/common/database.md`:

- Which module owns the table? It goes into that module's schema.
- Third normal form: each fact once; no repeating groups; no derived columns without a stated reason. Snapshot columns (price at the time of order) are fine and should be named as such.
- Every column: type, `NOT NULL` unless absence is a real state, default.
- Every reference: foreign key with delete rule, plus an index.
- Uniqueness rules as unique indexes (partial when soft delete is used).
- Indexes for the queries the feature will run (filters, sorting, joins).
- Enum columns: `string('<name>', 32)` + `CHECK` listing the values.

If the change touches a large existing table or removes/renames a column that deployed code uses, plan it in backwards-compatible steps and say so.

## 2. Create

```bash
php artisan make:migration add_reversed_at_to_transfers --path=app/Modules/Billing/Database/Migrations
```

Names state the change: `create_transfers_table`, `add_reversed_at_to_transfers`, `add_index_transfers_initiator_id_status`.

Then write `up()` and a real `down()`. Reference: `.claude/skills/new-endpoint/reference/app/Modules/Billing/Database/Migrations/2026_01_01_120000_create_billing_tables.php.tpl`.

```php
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('billing.transfers', static function (Blueprint $table): void {
            $table->timestampTz('reversed_at')->nullable();
            $table->index('reversed_at', 'idx_transfers_reversed_at');
        });
    }

    public function down(): void
    {
        Schema::table('billing.transfers', static function (Blueprint $table): void {
            $table->dropIndex('idx_transfers_reversed_at');
            $table->dropColumn('reversed_at');
        });
    }
};
```

## 3. Rules

- `declare(strict_types=1);`, anonymous class, `void` return types, schema-qualified table names.
- Name every index, unique and foreign key explicitly (`idx_`, `uq_`, `fk_`, `ck_` prefixes from `common/database.md`).
- `CHECK` constraints go through `DB::statement('ALTER TABLE ... ADD CONSTRAINT ck_... CHECK (...)')`.
- No application classes inside migrations (no models, enums, services). Literal values only.
- One logical change per migration. Schema and data changes in separate migrations.
- `CREATE INDEX CONCURRENTLY` and other statements that cannot run in a transaction: set `public $withinTransaction = false;` and note why in a comment.
- Never edit a committed migration. Fix forward with a new one.

## 4. After writing

- Update the model's `@property` docblock and `casts()`, the repository and the resource for new columns.
- Do not run `php artisan migrate` without the developer's confirmation. Show the command and what it will apply (`php artisan migrate:status`).
- After it is applied locally, verify the rollback once: `php artisan migrate:rollback --step=1` then `php artisan migrate`, with confirmation.
