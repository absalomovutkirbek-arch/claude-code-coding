---
name: new-module
description: Create a new business module (bounded context) with its Module class, database schema migration and registration in the configs. Use when a feature does not belong to any existing module.
argument-hint: "[module-name] [short purpose]"
---

# New module

Create the module `$ARGUMENTS`.

## 1. Decide whether a new module is right

A module is a business area with its own data (order, billing, catalog, notification), not a technical grouping and not a single screen. If the feature works mostly with tables an existing module owns, add it to that module instead and say so.

Module name: singular, lowercase, one word where possible (`order`, `billing`). The database schema uses the same name; if the name is an SQL reserved word, use the plural for the schema (`orders`) and record it in the Module docblock.

## 2. Preconditions

- `core/` exists. If not, run `/foundation` first.
- Read "Project facts" in `CLAUDE.md` for the root namespace and module root.

## 3. Create

1. `modules/<module>/Module.php`:

```php
<?php

declare(strict_types=1);

namespace app\modules\billing;

/**
 * Billing: wallets and transfers between them. Owns the `billing` schema.
 */
final class Module extends \yii\base\Module
{
    public $controllerNamespace = 'app\modules\billing\controllers';
}
```

2. Register in the web config: `'modules' => ['billing' => ['class' => app\modules\billing\Module::class]]`.
3. Add `'app\modules\<module>\migrations'` to `migrationNamespaces` in the console config.
4. Add an empty, commented section for the module in `config/container.php` and `config/routes.php`.
5. Create the schema migration with `/new-migration` (first migration: `CREATE SCHEMA IF NOT EXISTS <schema>`), together with the first tables if they are already known.

Do not create empty layer folders. They appear with their first class.

## 4. Public contract

If other modules will call this one, define what they may use in `modules/<module>/contracts/<Module>ApiInterface.php` (methods with DTO or scalar parameters and return values), implement it by a service, and bind it in `config/container.php`. Other modules depend only on that interface.

## 5. Report

List created files and config changes, and name the next step (usually `/new-endpoint`).
