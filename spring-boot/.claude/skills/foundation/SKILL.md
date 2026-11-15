---
name: foundation
description: Install the shared kernel (<base>.core) that every module depends on - API envelope records, global exception handler, domain exceptions, pipeline, actor ID resolver, security error handler. Use once per project, or when core classes are missing.
---

# Foundation: install the shared kernel

Install the kernel from `${CLAUDE_SKILL_DIR}/templates/` into this project. It is tested code. Copy it as is; do not rewrite or "improve" it.

## 1. Inspect first

- Read "Project facts" in `CLAUDE.md` for the base package and build tool. The templates use `com.example.app`.
- If `<base>.core` already exists, list what is there and install only the missing classes. Never overwrite an existing file without asking.
- Check the build file. The kernel needs Java 21 and Spring Boot 3.2+ with these starters: `web`, `validation`, `data-jpa`, `security`, plus `flyway-core`, `flyway-database-postgresql` and the PostgreSQL driver; for tests `spring-boot-starter-test` and `spring-security-test`. List what is missing and ask before adding dependencies.
- If the project already has a `@RestControllerAdvice`, a `SecurityFilterChain` or a `WebMvcConfigurer`, do not add a second one. Merge the kernel's behaviour into the existing class and say what you merged.

## 2. Copy

Copy every file under `templates/src/main/java/com/example/app/core/` to `src/main/java/<base path>/core/`, removing the `.tpl` suffix, keeping the folder structure and replacing `com.example.app` with the base package.

| Class | Purpose |
| --- | --- |
| `core.api.ApiResponse`, `PageMeta` | The only success envelope: `ApiResponse.of(data)`, `ApiResponse.page(page, mapper)` |
| `core.api.ApiError` | The only error envelope |
| `core.api.GlobalExceptionHandler` | The only exception -> HTTP mapping |
| `core.exception.*` | `DomainException` and its four standard children. Input validation uses Bean Validation |
| `core.pipeline.Handler`, `Pipeline` | Chain of Responsibility runner |
| `core.security.ActorId`, `ActorIdArgumentResolver` | `@ActorId long actorId` in controller methods |
| `core.security.ApiSecurityErrorHandler` | 401 / 403 from the security filter chain in the error envelope |
| `core.config.WebConfig` | Registers the resolver and the lowercase enum converter |
| `core.config.SecurityConfig` | Stateless API security skeleton |

Spring already provides the rest: `@Transactional` as the transaction boundary, `ApplicationEventPublisher` with `@TransactionalEventListener` for after-commit events, `Page` as the page object.

## 3. Wire the configuration

Add to `application.properties` (or the same keys in `application.yml`):

```properties
spring.jackson.property-naming-strategy=SNAKE_CASE
spring.jackson.mapper.accept-case-insensitive-enums=true

spring.jpa.open-in-view=false
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.jdbc.time_zone=UTC
spring.flyway.locations=classpath:db/migration
```

Datasource values come from environment variables (`${DB_URL}`, `${DB_USERNAME}`, `${DB_PASSWORD}`). Never write real credentials into a properties file.

Two places must be adapted to the project, and nowhere else:

- `SecurityConfig`: add the project's authentication mechanism where the comment marks it (recommended: `spring-boot-starter-oauth2-resource-server` with JWT) and list public endpoints.
- `ActorIdArgumentResolver.actorId()`: by default the authentication name is the numeric user ID (the JWT `sub` claim). Change this one method if the project keeps the ID elsewhere in the principal.

If the project also serves server-rendered pages, stop and ask how the API should be separated before installing `SecurityConfig` and `GlobalExceptionHandler` (the usual answer: restrict both to `/api/**` with a `securityMatcher` and `@RestControllerAdvice(basePackages = ...)`).

## 4. Verify

- Compile with the project's command (`./mvnw -q compile`).
- Start the application or run an existing `@SpringBootTest` and confirm the context loads.
- Request an unknown URL under `/api/` with authentication and confirm `{"error": {"code": "not_found", ...}}` with status 404; without authentication confirm 401 `unauthorized`.

## 5. Report

List the files created, the properties added, anything merged into existing classes or skipped, the dependencies the developer still has to approve, and the two adaptation points above.
