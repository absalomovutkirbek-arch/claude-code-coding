---
name: new-migration
description: Create a database migration for a module following the schema, naming, constraint and index rules. Use for any table, column, index or constraint change.
argument-hint: "[module] [what changes]"
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
- Enum columns: `string(32)` + `CHECK` listing the values.

If the change touches a large existing table or removes/renames a column that deployed code uses, plan it in backwards-compatible steps and say so.

## 2. Create

```bash
php yii migrate/create 'app\modules\<module>\migrations\<PascalCaseName>'
```

Names state the change: `CreateTransferTable`, `AddReversedAtToTransfer`, `AddIndexTransferInitiatorIdStatus`.

Then write `safeUp()` and a real `safeDown()`. Reference: `.claude/skills/new-endpoint/reference/modules/billing/migrations/M260101120000CreateBillingTables.php.tpl`.

```php
public function safeUp(): void
{
    $this->addColumn('billing.transfer', 'reversed_at', 'timestamptz NULL');
    $this->createIndex('idx_transfer_reversed_at', 'billing.transfer', 'reversed_at');
}

public function safeDown(): void
{
    $this->dropIndex('idx_transfer_reversed_at', 'billing.transfer');
    $this->dropColumn('billing.transfer', 'reversed_at');
}
```

## 3. Rules

- `declare(strict_types=1);`, `final class`, `void` return types.
- No application classes inside migrations (no models, enums, services). Literal values only.
- One logical change per migration. Schema and data changes in separate migrations.
- `CREATE INDEX CONCURRENTLY` and other statements that cannot run in a transaction use `up()` / `down()` instead of the safe variants; note why in a comment.
- Never edit a committed migration. Fix forward with a new one.

## 4. After writing

- Update the model's `@property` docblock, the repository and the resource for new columns.
- Do not run `php yii migrate` without the developer's confirmation. Show the command and what it will apply.
- After it is applied locally, verify the rollback once: `php yii migrate/down 1` then `php yii migrate`, with confirmation.
