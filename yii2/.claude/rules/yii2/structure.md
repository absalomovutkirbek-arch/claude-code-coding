# Yii2: structure and layer mapping

This file maps the stack-agnostic rules in `.claude/rules/common/` onto Yii2. Paths assume the basic template with root namespace `app\`. For the advanced template or another root, use the values in the "Project facts" section of `CLAUDE.md`.

## Module layout

```
core/                          Shared kernel (business-agnostic). Created by /foundation
  db/  events/  exceptions/  http/  pipeline/  data/  support/
config/
  container.php                Interface => implementation bindings, one section per module
  events.php                   Event class => listener classes
  routes.php                   Explicit URL rules, grouped by module
modules/<module>/
  Module.php
  controllers/<Entity>Controller.php          actions() map + verbs() only
  actions/<entity>/<Verb><Entity>Action.php   one class per endpoint
  forms/<Verb><Entity>Form.php                input rules + toDto()
  dto/<Verb><Entity>Dto.php                   immutable input for the service
  services/<Entity>Service.php                use cases, business rules, transaction
  services/handlers/<usecase>/<Step>Handler.php   pipeline steps (only when needed)
  strategies/<job>/<Variant><Job>.php         strategy variants (only when needed)
  repositories/<Entity>RepositoryInterface.php + <Entity>Repository.php
  models/<Entity>.php                         ActiveRecord: table mapping only
  resources/<Entity>Resource.php              output shape
  enums/  exceptions/  events/  listeners/  jobs/
  migrations/M<YYMMDDHHMMSS><Name>.php        namespaced migrations
tests/unit/modules/<module>/...               mirrors the module tree
tests/api/<module>/...                        endpoint tests
```

Create a folder only when its first class appears. A canonical, tested example of the whole slice is in `.claude/skills/new-endpoint/reference/`.

## Layer mapping

| Layer | Yii2 class | Key rule |
| --- | --- | --- |
| Controller | `extends app\core\http\ApiController` | Contains only `actions()` and `verbs()`. No inline `actionXxx()` methods |
| Action | `extends app\core\http\ApiAction`, method `run()` | Validate -> one service call -> `ok()` / `created()` / `paginated()` / `noContent()`. Service injected through the constructor |
| Form | `extends yii\base\Model` | `rules()` + `toDto()`. Untyped public properties. Never saves, never queries beyond `exist`/`unique` validators |
| DTO | `final class` with `public readonly` promoted properties | Built only by a form's `toDto()` (or by another service/job) |
| Service | `final class`, plain PHP | No `Yii::$app`, no ActiveQuery, no request/response. Uses `TransactionManagerInterface` and `EventDispatcherInterface` |
| Repository | interface + `final class` implementation | The only place with `::find()`, `findOne()`, `findBySql()`, `Query`, `createCommand()`, `save()`, `delete()` |
| Model | `final class extends yii\db\ActiveRecord` | `tableName()`, relations, `@property` docblock, named constructors, enum accessors. No `rules()`, no queries, no business logic |
| Resource | `final class` with static `make()` and `collection()` | The only place that builds response arrays |

## Wiring a new class

- New repository: bind interface -> implementation in `config/container.php` under the module's section.
- New endpoint: add the action to the controller's `actions()` and `verbs()`, and one line to `config/routes.php` as `'<VERB> v1/<resource>' => '<module>/<controller>/<action>'`.
- New module: register it in the `modules` section of the web config and add its migration namespace to `migrationNamespaces` in the console config.
- New listener: add it to `config/events.php`.
- Services, handlers, strategies and listeners are concrete classes resolved by the container automatically. Do not register them unless they implement a contract used by another module.

## Yii2-specific rules

- `declare(strict_types=1);` in every PHP file. PSR-12 formatting.
- Dependencies arrive only through constructors. In actions: `__construct($id, $controller, private readonly XService $service, array $config = [])` and call `parent::__construct($id, $controller, $config)`.
- `Yii::$app` is allowed only in `core/`, `config/`, actions (through `ApiAction` helpers) and listeners/jobs that need a framework component. Never in services, repositories, handlers, strategies, DTOs or resources.
- Repositories call `save(false)`: input is validated by forms and guarded by database constraints. If `save()` returns false, throw.
- Do not use `yii\rest\ActiveController`, `yii\rest\UrlRule` auto-routing, `ActiveDataProvider` in responses or `Model::load()` on ActiveRecord.
- Never bind `yii\db\Connection` in the container. Yii builds the `db` component through the same container and such a binding recurses.
- Statuses and types are backed PHP enums stored as strings. Models expose them through `<name>Enum()` accessors.
- Timestamps use `app\core\db\UtcTimestampBehavior`, not database expressions.

## Existing projects

When the project does not yet follow this layout: read "Project facts" in `CLAUDE.md`, apply the layout to new modules and new endpoints, and keep old controllers working. If `core/` is missing, run `/foundation` before the first new endpoint. See `common/workflow.md` for the legacy rules.
