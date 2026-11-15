---
name: adopt-project
description: Onboard this Claude Code setup onto a project - inspect the codebase, fill the Project facts in CLAUDE.md, and report how the existing code differs from the standard. Use right after installing the setup into a new or existing project.
disable-model-invocation: true
---

# Adopt project

Connect this setup to the project it was just installed into. This skill inspects and documents. It does not refactor.

## 1. Inspect

Gather facts from the code, not from assumptions:

- `composer.json`: PHP version, Laravel version, packages (sanctum or passport, horizon, octane, spatie packages, a modules package such as nwidart), test and analysis tools (phpunit or pest, larastan/phpstan, pint).
- Skeleton generation: Laravel 11+ (`bootstrap/app.php` with `withRouting()` and `bootstrap/providers.php`) or older (`app/Http/Kernel.php`, `app/Exceptions/Handler.php`, `config/app.php` providers).
- Database: driver and `search_path` from `config/database.php` (never read `.env`; read `.env.example`), schemas in use, where migrations live.
- Existing structure: where controllers, models, services, repositories, requests and resources live; whether modules or domains exist; how routes are declared; how authentication works; how responses and errors are shaped today.
- Conventions already in place: naming, JSON casing, table naming, response envelope, API prefix and versioning.
- How the project is run: Sail, docker compose, plain PHP, Makefile targets.

## 2. Fill "Project facts" in CLAUDE.md

Replace the placeholder values with what you found, including the exact commands for tests, static analysis, code style and migrations (with the `sail` or docker prefix if the project runs in containers). Add a 3-5 line description of the business domain and list existing modules with one line each. If something cannot be determined, write `unknown - ask` and include it in the questions.

## 3. Classify the project

- **New / empty**: propose running `/foundation`, then `/new-module` for the first module.
- **Existing, compatible**: already layered in a similar way (services, repositories or actions exist). Map its names onto the standard (for example its `app/Actions` = our services) and record the mapping in "Project facts" so new code follows the existing names.
- **Existing, different** (logic in controllers or Eloquent models, no services): record that new modules and endpoints follow the standard under `app/Modules/` and `app/Core/`, while old code stays as is and is improved only where touched.

## 4. Conflicts between the project and the standard

Where the project already has an established convention that differs from the rules (response envelope, JSON casing, table naming, auth method, Blade or Inertia pages sharing the app, SQLite tests, MySQL instead of PostgreSQL), do not change it. List each conflict with two options, keeping the project's way or migrating to the standard, and a recommendation. Record the developer's decision in "Project facts" under "Project-specific overrides".

## 5. Report

```
## Project profile
<facts table>

## How new code will be written here
<5-8 lines: where modules live, namespaces, commands>

## Differences from the standard
| Area | Project today | Standard | Recommendation |

## Questions
<only business or decision questions that the code cannot answer>

## Suggested first steps
1. ...
```

Do not create, move or rewrite application code in this skill. The only file edited is `CLAUDE.md`.
