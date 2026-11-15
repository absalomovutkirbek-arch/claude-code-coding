---
name: foundation
description: Install the shared kernel (core/) that every module depends on - API base controller and action, error handler, domain exceptions, transaction manager, pipeline, event dispatcher. Use once per project, or when core/ classes are missing.
---

# Foundation: install the shared kernel

Install the kernel from `${CLAUDE_SKILL_DIR}/templates/` into this project. It is tested code. Copy it as is; do not rewrite or "improve" it.

## 1. Inspect first

- Read "Project facts" in `CLAUDE.md` for the root namespace and paths. Defaults: namespace `app\`, kernel in `core/`, config in `config/`.
- If `core/` already exists, list what is there and install only the missing classes. Never overwrite an existing file without asking.
- Check the PHP version in `composer.json`. The kernel needs PHP 8.1+. If the project is older, stop and report.

## 2. Copy

- Copy every file under `templates/core/` to `<root>/core/`, removing the `.tpl` suffix and keeping the folder structure.
- Copy `templates/config/container.php.tpl`, `events.php.tpl` and `routes.php.tpl` to `config/` only if those files do not exist. If they exist, merge the kernel bindings into them.
- If the root namespace is not `app\`, replace `app\core` with `<root>\core` in the copied files.

| Class | Purpose |
| --- | --- |
| `core/http/ApiController` | Base controller: JSON only, bearer authentication, `publicActions()` |
| `core/http/ApiAction` | Base action: `validateBody()`, `validateQuery()`, `actorId()`, `ok()`, `created()`, `paginated()`, `noContent()` |
| `core/http/ApiErrorHandler` | The only exception -> HTTP mapping. Renders the error envelope |
| `core/exceptions/*` | `DomainException` and its five standard children |
| `core/db/TransactionManagerInterface`, `DbTransactionManager` | Transaction boundary for services |
| `core/db/UtcTimestampBehavior` | `created_at` / `updated_at` as UTC strings |
| `core/pipeline/Pipeline`, `HandlerInterface` | Chain of Responsibility runner |
| `core/events/EventDispatcherInterface`, `EventDispatcher` | After-commit domain events |
| `core/data/Page` | Paginated repository result |
| `core/support/Iso8601` | Timestamp formatting for resources |

## 3. Wire the configuration

Apply these to the web config (`config/web.php`). Keep existing values that are unrelated.

```php
'container' => require __DIR__ . '/container.php',
'components' => [
    'request' => [
        'enableCsrfValidation' => false,
        'enableCookieValidation' => false,
        'parsers' => ['application/json' => yii\web\JsonParser::class],
    ],
    'response' => ['format' => yii\web\Response::FORMAT_JSON],
    'errorHandler' => ['class' => app\core\http\ApiErrorHandler::class],
    'user' => [
        'identityClass' => app\models\User::class, // keep the project's identity class
        'enableSession' => false,
        'loginUrl' => null,
    ],
    'urlManager' => [
        'enablePrettyUrl' => true,
        'enableStrictParsing' => true,
        'showScriptName' => false,
        'rules' => require __DIR__ . '/routes.php',
    ],
],
```

Console config (`config/console.php`):

```php
'container' => require __DIR__ . '/container.php',
'controllerMap' => [
    'migrate' => [
        'class' => yii\console\controllers\MigrateController::class,
        'migrationPath' => null, // or keep '@app/migrations' for legacy migrations
        'migrationNamespaces' => [
            // 'app\modules\<module>\migrations',
        ],
    ],
],
```

The test config loads the same `container.php`.

If the project also serves HTML pages (not API-only), do not change the global `request`, `response`, `errorHandler` and `user` components. Stop and ask how the API should be separated (a dedicated API entry script or application is the usual answer).

## 4. Verify

- `php -l` on every copied file.
- `composer dump-autoload` if the autoload configuration changed.
- Request an unknown URL and confirm the response is `{"error": {"code": "not_found", ...}}` with status 404.

## 5. Report

List the files created, the config keys changed, anything skipped because it already existed, and remind the developer that the identity class must implement `findIdentityByAccessToken()` for bearer authentication.
