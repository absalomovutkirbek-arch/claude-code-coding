---
name: new-migration
description: Create a Flyway SQL migration for a module following the schema, naming, constraint and index rules. Use for any table, column, index or constraint change.
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
- Uniqueness rules as unique constraints or indexes (partial when soft delete is used).
- Indexes for the queries the feature will run (filters, sorting, joins).
- Enum columns: `VARCHAR(32)` + `CHECK` listing the Java enum constants.

If the change touches a large existing table or removes/renames a column that deployed code uses, plan it in backwards-compatible steps (add, backfill, switch code, drop later) and say so.

## 2. Create

File: `src/main/resources/db/migration/<module>/V<yyyyMMddHHmmss>__<snake_case_name>.sql`. Use the current UTC time for the version and two underscores before the name.

Names state the change: `create_transfer_table`, `add_reversed_at_to_transfer`, `add_index_transfer_initiator_id_status`.

Reference: `.claude/skills/new-endpoint/reference/src/main/resources/db/migration/billing/V20260101120000__create_billing_tables.sql.tpl`.

```sql
ALTER TABLE billing.transfer
    ADD COLUMN reversed_at TIMESTAMPTZ NULL;

CREATE INDEX idx_transfer_reversed_at ON billing.transfer (reversed_at);
```

## 3. Rules

- Plain PostgreSQL SQL, uppercase keywords, schema-qualified table names, every constraint and index named (`pk_`/`fk_`/`uq_`/`ck_`/`idx_` from `common/database.md`).
- One logical change per migration. Schema and data changes in separate files.
- Flyway is forward-only. There is no down script; a committed migration is never edited, it is corrected by a new one.
- Adding a `NOT NULL` column to a table with rows needs a default or a three-step change (add nullable, backfill, set `NOT NULL`).
- `CREATE INDEX CONCURRENTLY` cannot run in a transaction: put it alone in its own file and add a script config file next to it (`<same name>.sql.conf` with `executeInTransaction=false`). Note why in a comment.
- Java-based migrations only when SQL cannot express the change, and then without application classes (no entities, enums, services).

## 4. After writing

- Update the entity (`@Column` mapping, getters), the repository and the response record for new columns. `ddl-auto=validate` fails at startup if the entity and the schema disagree.
- Run the module's API test: it applies the migration to the test database and validates the mapping.
- Do not start the application against a shared or production database to apply the migration. Tell the developer which migration will run on the next deploy.
