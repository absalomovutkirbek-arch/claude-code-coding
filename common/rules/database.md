# Database

## Schemas and ownership

- One database schema per business module (`orders`, `billing`, `catalog`). On engines without schemas (MySQL), use a module prefix: `orders_order`, `orders_item`.
- A table belongs to exactly one module. Only that module's repositories query it.
- Shared reference data (countries, currencies) lives in a `reference` / `common` schema and is read-only for business modules.

## Normalization

- Design to third normal form by default: one fact in one place, no repeating groups, no columns that depend on a non-key column.
- Denormalize only for a measured read problem, and write the reason in the migration comment. Snapshot columns are the legitimate exception: copy values that must not change later (price and product name on an order item).
- Many-to-many relations use a junction table with its own composite unique key.
- No comma-separated lists or JSON blobs for data you filter, join or aggregate on. JSON columns are for opaque payloads only.

## Naming

- Tables and columns in `snake_case`. Pick singular or plural table names once per project and keep it; default is singular (`order`, `order_item`).
- Primary key `id`. Foreign key `<referenced_table>_id`.
- Booleans `is_...` / `has_...`. Timestamps `..._at`. Dates `..._on` or `..._date`.
- Index `idx_<table>_<columns>`, unique `uq_<table>_<columns>`, foreign key `fk_<table>_<column>`.

## Columns

- Every table has `id`, `created_at`, `updated_at`. Add `created_by` / `updated_by` where an audit trail matters.
- `NOT NULL` by default. Allow `NULL` only when "unknown / not applicable" is a real state.
- Money: `DECIMAL(19,4)` or integer minor units, plus a currency column when more than one currency is possible. Never float.
- Time: UTC, timezone-aware type where the engine has one (`timestamptz`).
- Status and type columns: short strings (`varchar(32)`) matching the code enum, guarded by a `CHECK` constraint or a native enum.
- Soft delete (`deleted_at`) only where the business needs to restore or audit. When used, unique indexes must be partial (`WHERE deleted_at IS NULL`).

## Integrity

- Declare every foreign key in the database, with an explicit `ON DELETE` rule (`RESTRICT` by default, `CASCADE` only for owned children).
- Enforce uniqueness with unique indexes, not only with application checks.
- Index every foreign key and every column used in `WHERE`, `JOIN` or `ORDER BY` of a frequent query. Composite index column order follows the query (equality columns first).
- Cross-module references use an ID column. Add a database foreign key across schemas only when both modules will always live in the same database.

## Migrations

- Every schema change goes through a migration. No manual changes, no schema changes in application code.
- Never edit a migration that has been applied anywhere outside your machine. Write a new one.
- One logical change per migration, with a working rollback. If a rollback is impossible (data loss), state it explicitly in the migration.
- Migrations are deterministic: no dependence on application models, services or current data assumptions that may change.
- Data migrations are separate from schema migrations.
- Changes to large tables are backwards compatible in steps: add nullable column -> backfill -> enforce constraint -> remove old column in a later release.

## Queries

- All queries live in repositories. No query building in services, controllers or views.
- Always parameterize. Never concatenate input into SQL.
- Select what you need. Avoid N+1: load relations eagerly for collections.
- List queries always have a `LIMIT`. Paginate large exports in chunks.
- Use `SELECT ... FOR UPDATE` (or optimistic version columns) when concurrent requests can change a value you decide on.
