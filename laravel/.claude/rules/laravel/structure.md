# Laravel: structure and layer mapping

This file maps the stack-agnostic rules in `.claude/rules/common/` onto Laravel 11+ (PHP 8.2+). Paths assume the default skeleton with root namespace `App\`. For other values, use the "Project facts" section of `CLAUDE.md`.

## Module layout

```
app/Core/                        Shared kernel (business-agnostic). Created by /foundation
  Db/  Exceptions/  Http/  Pipeline/  Providers/
app/Modules/<Module>/
  Providers/<Module>ServiceProvider.php       bindings, routes, migrations, listeners of the module
  routes/api.php                              one explicit line per endpoint
  Http/Actions/<Entity>/<Verb><Entity>Action.php   one invokable class per endpoint
  Http/Requests/<Verb><Entity>Request.php     input rules + toDto()
  Http/Resources/<Entity>Resource.php         output shape
  Dto/<Verb><Entity>Dto.php                   immutable input for the service
  Services/<Entity>Service.php                use cases, business rules, transaction
  Services/Handlers/<Usecase>/<Step>Handler.php   pipeline steps (only when needed)
  Strategies/<Job>/<Variant><Job>.php         strategy variants (only when needed)
  Repositories/<Entity>RepositoryInterface.php + <Entity>Repository.php
  Models/<Entity>.php                         Eloquent: table mapping only
  Enums/  Exceptions/  Events/  Listeners/  Jobs/
  Database/Migrations/<timestamp>_<name>.php
tests/Unit/Modules/<Module>/...               mirrors the module tree, no framework boot
tests/Feature/Modules/<Module>/...            endpoint tests against PostgreSQL
```

Create a folder only when its first class appears. A canonical, tested example of the whole slice is in `.claude/skills/new-endpoint/reference/`.

## Layer mapping

| Layer | Laravel class | Key rule |
| --- | --- | --- |
| Controller + Action | Invokable `final class` in `Http/Actions`, route points at it | `__invoke()` = one service call -> `ApiResponse::ok()` / `created()` / `paginated()` / `noContent()`. Service injected through the constructor. No multi-method controllers |
| Form | `final class extends FormRequest` | `rules()` + `toDto()`. Never saves, never queries beyond `exists` / `unique` rules |
| DTO | `final readonly class` with promoted properties | Built only by a request's `toDto()` (or by another service/job) |
| Service | `final class`, plain PHP | No facades, no helpers that reach the container or the request, no Eloquent queries. Uses `TransactionManagerInterface` and `Illuminate\Contracts\Events\Dispatcher` |
| Repository | interface + `final class` implementation | The only place with `Model::query()`, static Eloquent calls, `DB::`, `->save()`, `->delete()` |
| Model | `final class extends Model` | `$table`, `casts()`, relations, `@property` docblock, named constructors. No queries, no business logic, no observers with side effects |
| Resource | `final class extends JsonResource` | The only place that builds response arrays |

Laravel routes point directly at a class, so the "controller that maps actions" from the common rules is the route file plus the Action class.

## Wiring a new class

Everything a module needs is registered in its own `Providers/<Module>ServiceProvider.php`:

- New repository: add interface => implementation to the provider's `$bindings`.
- New endpoint: one line in the module's `routes/api.php`. The provider applies the prefix `api/v1/<module>` and the middleware `['api', 'auth:sanctum']`.
- New listener: `Event::listen(<Event>::class, <Listener>::class)` in the provider's `boot()`.
- New module: register its provider in `bootstrap/providers.php` and add its schema to `search_path` in `config/database.php`.
- Services, handlers, strategies and listeners are concrete classes resolved by the container automatically. Do not bind them unless they implement a contract used by another module.

## Laravel-specific rules

- `declare(strict_types=1);` in every PHP file. Formatting is whatever `vendor/bin/pint` produces; run it on changed files.
- Dependencies arrive only through constructors. Inject contracts (`Illuminate\Contracts\Events\Dispatcher`, `Illuminate\Contracts\Cache\Repository`, `Psr\Log\LoggerInterface`), not facades.
- Facades and helpers (`DB::`, `Auth::`, `Event::`, `app()`, `request()`, `auth()`, `event()`) are allowed only in service providers, route files, migrations, `app/Core/` and tests.
- No implicit route model binding. Route parameters are scalars (`int $id`); the service loads the record through a repository and checks ownership.
- No mass assignment from request data: no `Model::create($request->all())`, no `$model->fill($request->validated())`. Models are built by named constructors and changed by explicit attribute assignment in the service.
- Do not use `Route::resource()`, `Route::apiResource()`, API resource collections that paginate by themselves, or controllers with several actions.
- `Model::shouldBeStrict()` is enabled outside production by `CoreServiceProvider`: lazy loading, unknown attributes and silently discarded fills throw. Fix the cause, do not disable it.
- Statuses and types are backed PHP enums stored as strings and declared in the model's `casts()`.
- Tables carry the module schema in the model: `protected $table = 'billing.transfers';`.

## Existing projects

When the project does not yet follow this layout: read "Project facts" in `CLAUDE.md`, apply the layout to new modules and new endpoints, and keep old controllers working. If `app/Core/` is missing, run `/foundation` before the first new endpoint. See `common/workflow.md` for the legacy rules.
