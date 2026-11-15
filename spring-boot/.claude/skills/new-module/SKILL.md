---
name: new-module
description: Create a new business module (bounded context) with its package, database schema migration and public contract. Use when a feature does not belong to any existing module.
argument-hint: "[module-name] [short purpose]"
---

# New module

Create the module `$ARGUMENTS`.

## 1. Decide whether a new module is right

A module is a business area with its own data (order, billing, catalog, notification), not a technical grouping and not a single screen. If the feature works mostly with tables an existing module owns, add it to that module instead and say so.

Module name: singular, lowercase, one word where possible (`order`, `billing`). The package, the database schema, the migration folder and the URL segment all use it; if the name is an SQL reserved word, use the plural for the schema (`orders`) and record it in `package-info.java`.

## 2. Preconditions

- `<base>.core` exists. If not, run `/foundation` first.
- Read "Project facts" in `CLAUDE.md` for the base package and API prefix.

## 3. Create

1. `src/main/java/<base path>/modules/<module>/package-info.java`:

```java
/**
 * Billing: wallets and transfers between them. Owns the {@code billing} schema.
 *
 * <p>Other modules may use only the types in {@code contract}.
 */
package com.example.app.modules.billing;
```

2. The schema migration with `/new-migration`: `src/main/resources/db/migration/<module>/V<timestamp>__create_<module>_schema.sql` starting with `CREATE SCHEMA IF NOT EXISTS <module>;`, together with the first tables if they are already known.

Nothing has to be registered: component scanning finds the module's classes and Flyway scans `db/migration` recursively. Do not create empty layer packages. They appear with their first class.

## 4. Public contract

If other modules will call this one, define what they may use in `modules/<module>/contract/<Module>Api.java` (an interface whose methods take and return records or scalars, never entities), and implement it by a service of the module. Other modules inject only that interface. They never import this module's entities, repositories or services, and never query its tables.

## 5. Report

List created files and name the next step (usually `/new-endpoint`).
