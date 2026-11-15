---
name: adopt-project
description: Onboard this Claude Code setup onto a project - inspect the codebase, fill the Project facts in CLAUDE.md, and report how the existing code differs from the standard. Use right after installing the setup into a new or existing project.
disable-model-invocation: true
---

# Adopt project

Connect this setup to the project it was just installed into. This skill inspects and documents. It does not refactor.

## 1. Inspect

Gather facts from the code, not from assumptions:

- Build file (`pom.xml` or `build.gradle(.kts)`): Java version, Spring Boot version, starters (web or webflux, data-jpa, security, validation), migration tool (Flyway or Liquibase), Lombok, MapStruct, test libraries (Testcontainers), formatter or linter plugins (Spotless, Checkstyle).
- Base package: the package of the `@SpringBootApplication` class.
- Database: driver and settings from `application.yml` / `application.properties` and profiles (never read `.env` or files with real secrets), schemas in use, where migrations live and how they are named.
- Existing structure: package-by-layer (`controller`, `service`, `repository` at the top) or package-by-feature; how controllers, services, repositories, DTOs and mappers are named; how authentication works (JWT resource server, custom filter, session); how responses and errors are shaped today (`@ControllerAdvice`, `ProblemDetail`, custom envelope).
- Conventions already in place: JSON casing, table naming, enum storage, ID types (`Long` or `UUID`), API prefix and versioning.
- How the project is run: wrapper script (`./mvnw`, `./gradlew`), docker compose, profiles.

## 2. Fill "Project facts" in CLAUDE.md

Replace the placeholder values with what you found, including the exact commands for compiling, tests and code style. Add a 3-5 line description of the business domain and list existing modules with one line each. If something cannot be determined, write `unknown - ask` and include it in the questions.

## 3. Classify the project

- **New / empty**: propose running `/foundation`, then `/new-module` for the first module.
- **Existing, compatible**: already layered controller -> service -> repository with DTOs. Map its names onto the standard (for example its `payload` package = our `request`/`response`, its `model` = our `entity`) and record the mapping in "Project facts" so new code follows the existing names.
- **Existing, different** (logic in controllers, entities returned from the API, no DTOs): record that new modules and endpoints follow the standard under `<base>.modules` and `<base>.core`, while old code stays as is and is improved only where touched.

## 4. Conflicts between the project and the standard

Where the project already has an established convention that differs from the rules (response envelope or `ProblemDetail`, `camelCase` JSON, package-by-layer, Liquibase, Lombok, MapStruct, `UUID` keys, WebFlux, H2 tests), do not change it. List each conflict with two options, keeping the project's way or migrating to the standard, and a recommendation. Record the developer's decision in "Project facts" under "Project-specific overrides".

## 5. Report

```
## Project profile
<facts table>

## How new code will be written here
<5-8 lines: where modules live, packages, commands>

## Differences from the standard
| Area | Project today | Standard | Recommendation |

## Questions
<only business or decision questions that the code cannot answer>

## Suggested first steps
1. ...
```

Do not create, move or rewrite application code in this skill. The only file edited is `CLAUDE.md`.
