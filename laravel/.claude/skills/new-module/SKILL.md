---
name: new-module
description: Create a new business module (bounded context) with its service provider, routes file, database schema migration and registration. Use when a feature does not belong to any existing module.
argument-hint: "[ModuleName] [short purpose]"
---

# New module

Create the module `$ARGUMENTS`.

## 1. Decide whether a new module is right

A module is a business area with its own data (order, billing, catalog, notification), not a technical grouping and not a single screen. If the feature works mostly with tables an existing module owns, add it to that module instead and say so.

Module name: singular, `PascalCase`, one word where possible (`Order`, `Billing`). The database schema and the URL segment use the lowercase name; if the name is an SQL reserved word, use the plural for the schema (`orders`) and record it in the provider docblock.

## 2. Preconditions

- `app/Core/` exists. If not, run `/foundation` first.
- Read "Project facts" in `CLAUDE.md` for the root namespace, module root, API prefix and auth middleware.

## 3. Create

1. `app/Modules/<Module>/Providers/<Module>ServiceProvider.php`:

```php
<?php

declare(strict_types=1);

namespace App\Modules\Billing\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

/**
 * Billing: wallets and transfers between them. Owns the `billing` schema.
 */
final class BillingServiceProvider extends ServiceProvider
{
    /** @var array<class-string, class-string> Repository interface => implementation. */
    public array $bindings = [];

    public function boot(): void
    {
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');

        Route::middleware(['api', 'auth:sanctum'])
            ->prefix('api/v1/billing')
            ->group(__DIR__.'/../routes/api.php');
    }
}
```

2. `app/Modules/<Module>/routes/api.php` with `declare(strict_types=1);`, the `Route` import and a comment naming the prefix. Endpoints are added by `/new-endpoint`.
3. Register the provider in `bootstrap/providers.php`.
4. Add the schema to `search_path` in `config/database.php` and to `DB_SEARCH_PATH` in `.env.example` and `phpunit.xml` (for example `public,billing`). Tell the developer to update their own `.env`.
5. Create the schema migration with `/new-migration` (first statement: `CREATE SCHEMA IF NOT EXISTS <schema>`), together with the first tables if they are already known.

Do not create empty layer folders. They appear with their first class. The full shape of a finished provider is `.claude/skills/new-endpoint/reference/app/Modules/Billing/Providers/BillingServiceProvider.php.tpl`.

## 4. Public contract

If other modules will call this one, define what they may use in `app/Modules/<Module>/Contracts/<Module>ApiInterface.php` (methods with DTO or scalar parameters and return values), implement it by a service, and bind it in the provider's `$bindings`. Other modules depend only on that interface, never on this module's models or repositories.

## 5. Report

List created files and config changes, run `php artisan route:list --path=api/v1/<module>` once the first route exists, and name the next step (usually `/new-endpoint`).
