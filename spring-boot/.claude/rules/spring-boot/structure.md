# Spring Boot: structure and layer mapping

This file maps the stack-agnostic rules in `.claude/rules/common/` onto Spring Boot 3 (Java 21, Spring MVC, Spring Data JPA, Flyway, PostgreSQL). `<base>` is the base package from "Project facts" in `CLAUDE.md`; examples use `com.example.app`.

## Package layout

```
<base>.core                          Shared kernel (business-agnostic). Created by /foundation
  api/         ApiResponse, PageMeta, ApiError, GlobalExceptionHandler
  exception/   DomainException and its four standard children
  pipeline/    Handler, Pipeline
  security/    @ActorId, ActorIdArgumentResolver, ApiSecurityErrorHandler
  config/      WebConfig, SecurityConfig
<base>.modules.<module>
  controller/<Entity>Controller           one class per resource, one thin method per endpoint
  request/<Verb><Entity>Request           record: Bean Validation + toDto(actorId)
  dto/<Verb><Entity>Dto                   record: immutable input for the service
  response/<Entity>Response               record: output shape, static from(entity)
  service/<Entity>Service                 use cases, business rules, @Transactional
  service/handler/<usecase>/<Step>Handler pipeline steps (only when needed)
  strategy/<job>/<Variant><Job>           strategy variants (only when needed)
  repository/<Entity>Repository           Spring Data JPA interface
  entity/<Entity>                         JPA entity: table mapping only
  enums/  exception/  event/  listener/
src/main/resources/db/migration/<module>/V<yyyyMMddHHmmss>__<name>.sql
src/test/java/<base>/modules/<module>/service/<Entity>ServiceTest      unit, no Spring context
src/test/java/<base>/modules/<module>/controller/<Entity>ApiTest       endpoint test on PostgreSQL
```

Create a package only when its first class appears. A canonical, tested example of the whole slice is in `.claude/skills/new-endpoint/reference/`.

## Layer mapping

| Layer | Spring class | Key rule |
| --- | --- | --- |
| Controller + Action | `@RestController`, one per resource. Each handler method is the "action" | Method body: `request.toDto(actorId)` -> one service call -> `ApiResponse.of(Response.from(...))`. No `if`, loops, repositories, `try/catch`, `ResponseEntity` |
| Form | `record <Verb><Entity>Request` | Bean Validation annotations + `toDto(long actorId)`. No Spring beans, no queries |
| DTO | `record <Verb><Entity>Dto` | Built only by a request's `toDto()` (or by another service/job) |
| Service | `@Service` class with constructor injection | Owns the transaction and the business rules. No web or security types, no `EntityManager` |
| Repository | `interface ... extends JpaRepository<Entity, Long>` | The only place with queries. Spring Data already gives the interface, so no extra implementation class unless a query needs Criteria or native SQL |
| Model | `@Entity` class | Columns, relations, static factories, small state methods. No business rules, no service calls |
| Resource | `record <Entity>Response` with `static from(Entity)` | The only place that shapes output. Entities are never serialised |

## Wiring

- Components are found by scanning: `@RestController`, `@Service`, `@Component` (listeners, handlers, strategies). Do not write `@Bean` methods for them.
- New endpoint: a method in the resource's controller with an explicit mapping. Class-level `@RequestMapping("/api/v1/<module>/<resources>")`.
- New listener: a `@Component` with a `@TransactionalEventListener(phase = AFTER_COMMIT)` method.
- New module: a new package under `<base>.modules` and a new folder under `db/migration`. Nothing to register.
- Public (unauthenticated) endpoints are listed explicitly in `SecurityConfig`.

## Spring-specific rules

- Constructor injection with `private final` fields. No field or setter injection, no `@Autowired` on fields, no `ApplicationContext.getBean()`.
- Records for requests, DTOs, responses, events and other value carriers. Classes for entities, services and components. Lombok only if "Project facts" says the project uses it, and never `@Data` on an entity.
- Spring proxies need non-final classes: do not mark `@Service`, `@Component`, `@Configuration` or `@Entity` classes `final`. Everything else (records, exceptions, utility classes) may be.
- The authenticated user reaches the code only as `@ActorId long actorId` in a controller method and travels on in the DTO.
- JSON is `snake_case` through `spring.jackson.property-naming-strategy=SNAKE_CASE`; Java stays `camelCase`. Never put `@JsonProperty` on every field to get snake case.
- Enums are `UPPER_SNAKE_CASE` in Java and in the database (`@Enumerated(EnumType.STRING)`), and lowercase in the API through a `@JsonValue` method. Input accepts them case-insensitively.
- Time is `Instant` in entities, DTOs and responses (`timestamptz` in the database). No `Date`, `LocalDateTime` or `Timestamp` for points in time.
- Money is `long` minor units or `BigDecimal`. Never `double` or `float`.
- `spring.jpa.open-in-view=false` and `spring.jpa.hibernate.ddl-auto=validate` stay as the kernel sets them. Hibernate never creates or alters tables.
- Use `Optional` only as a repository return type. No `Optional` parameters or fields.
- Log through SLF4J with placeholders. No `System.out`, no `printStackTrace()`.

## Existing projects

When the project does not yet follow this layout: read "Project facts" in `CLAUDE.md`, apply the layout to new modules and new endpoints, and keep old controllers working. If `<base>.core` is missing, run `/foundation` before the first new endpoint. See `common/workflow.md` for the legacy rules.
