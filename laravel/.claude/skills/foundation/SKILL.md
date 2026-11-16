---
name: foundation
description: Install the shared kernel (app/Core) that every module depends on - API response builder, exception renderer, domain exceptions, transaction manager, pipeline handler contract. Use once per project, or when app/Core classes are missing.
---

# Foundation: install the shared kernel

Install the kernel from `${CLAUDE_SKILL_DIR}/templates/` into this project. It is tested code. Copy it as is; do not rewrite or "improve" it.

## 1. Inspect first

- Read "Project facts" in `CLAUDE.md` for the root namespace and paths. Defaults: namespace `App\`, kernel in `app/Core/`.
- If `app/Core/` already exists, list what is there and install only the missing classes. Never overwrite an existing file without asking.
- Check `composer.json`. The kernel needs PHP 8.2+ and Laravel 11+. On Laravel 10 see "Older skeleton" below. If PHP is older than 8.2, stop and report.

## 2. Copy

Copy every file under `templates/app/Core/` to `app/Core/`, removing the `.tpl` suffix and keeping the folder structure. If the root namespace is not `App\`, replace it in the copied files.

| Class | Purpose |
| --- | --- |
| `Core/Http/ApiResponse` | The only success response builder: `ok()`, `created()`, `paginated()`, `noContent()` |
| `Core/Http/ApiExceptionRenderer` | The only exception -> HTTP mapping. Renders the error envelope |
| `Core/Exceptions/*` | `DomainException` and its four standard children. Input validation uses Laravel's `ValidationException` |
| `Core/Db/TransactionManagerInterface`, `DbTransactionManager` | Transaction boundary for services |
| `Core/Pipeline/HandlerInterface` | Contract of a pipeline step run by `Illuminate\Pipeline\Pipeline` |
| `Core/Providers/CoreServiceProvider` | Binds the transaction manager, enables strict Eloquent outside production |

Laravel already provides the rest: the event dispatcher with `ShouldDispatchAfterCommit`, `Illuminate\Pipeline\Pipeline`, `LengthAwarePaginator` as the page object.

## 3. Wire the configuration

`bootstrap/providers.php`:

```php
return [
    App\Providers\AppServiceProvider::class,
    App\Core\Providers\CoreServiceProvider::class,
    // module providers are added by /new-module
];
```

`bootstrap/app.php`:

```php
->withExceptions(function (Exceptions $exceptions): void {
    App\Core\Http\ApiExceptionRenderer::register($exceptions);
})
```

`config/database.php`, connection `pgsql`. Module schemas are appended to this value by `/new-module`:

```php
'search_path' => env('DB_SEARCH_PATH', 'public'),
```

Authentication: the standard uses Sanctum (`auth:sanctum`). If the project has no API authentication yet, propose `php artisan install:api` and wait for confirmation, because it adds a package and a migration. If the project uses Passport or another guard, keep it and record the middleware name in "Project facts".

Tests: in `phpunit.xml` set `DB_CONNECTION=pgsql`, a dedicated test `DB_DATABASE` and `DB_SEARCH_PATH`. Ask the developer to create the test database; do not create databases yourself.

If the project also serves HTML pages (Blade, Inertia, Livewire), nothing else changes: the renderer only handles `api/*` requests and requests that expect JSON.

## Older skeleton (Laravel 10)

There is no `bootstrap/providers.php` and no `withExceptions()`:

- Register providers in `config/app.php` under `providers`.
- In `App\Exceptions\Handler::register()` add `$this->renderable(ApiExceptionRenderer::render(...));` and add `DomainException::class` to `$dontReport`.
- `ApiExceptionRenderer::register()` is then unused; remove that method and its `Exceptions` import from the copied file.

## 4. Verify

- `php -l` on every copied file, then `vendor/bin/pint app/Core`.
- `php artisan about` runs without errors.
- Request an unknown URL under `/api/` and confirm the response is `{"error": {"code": "not_found", ...}}` with status 404.

## 5. Report

List the files created, the config files changed, anything skipped because it already existed, and what the developer has to do by hand (test database, `.env` values such as `DB_SEARCH_PATH`).
