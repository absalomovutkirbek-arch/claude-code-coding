---
paths:
  - "src/test/**/*.java"
---

# Spring Boot: testing

Follow `common/testing.md` for what to test. This file covers how in Spring Boot.

- JUnit 5, Mockito and AssertJ from `spring-boot-starter-test`. Run with the command in "Project facts" (`./mvnw test`).
- Tests mirror the main tree: `src/test/java/<base>/modules/<module>/service/<Entity>ServiceTest`, `.../controller/<Entity>ApiTest`.
- Method names: `<method>_<behaviour>` in camelCase with one underscore (`create_failsWhenBalanceIsInsufficient`). Test classes and methods are package-private.
- Assertions use AssertJ (`assertThat`, `assertThatThrownBy`). No JUnit `assertEquals`, no Hamcrest outside MockMvc matchers.

## Service tests (unit)

```java
@ExtendWith(MockitoExtension.class)
class TransferServiceTest {

    @Mock
    private WalletRepository wallets;

    @Mock
    private TransferRepository transfers;

    @Mock
    private ApplicationEventPublisher events;

    private TransferService service;

    @BeforeEach
    void setUp() {
        service = new TransferService(wallets, transfers, events);
    }
}
```

- No Spring context: no `@SpringBootTest`, no `@MockitoBean`. The service is built with `new` and mocks. If that is impossible, the service has a hidden dependency and must be fixed.
- Mocked `save()` returns its argument and assigns an ID when the code reads it afterwards: `thenAnswer` + `ReflectionTestUtils.setField(saved, "id", 77L)`.
- Build entities through their static factories in a private helper.
- Assert the specific exception class with `assertThatThrownBy`, and that nothing was saved or published on failure (`verify(..., never())`).

The complete example is `.claude/skills/new-endpoint/reference/src/test/java/com/example/app/modules/billing/service/TransferServiceTest.java.tpl`.

## Endpoint tests (API)

- `@SpringBootTest` + `@AutoConfigureMockMvc` against PostgreSQL, never H2: schemas, `CHECK` constraints, row locks and Flyway migrations must behave as in production. The test datasource is the project's test database or Testcontainers (`jdbc:tc:postgresql:16:///test`), configured in the test properties.
- Do not put `@Transactional` on API tests: after-commit listeners would never run. Clean the module's tables in `@BeforeEach` with `TRUNCATE ... RESTART IDENTITY CASCADE`.
- Authenticate with `.with(user("<id>"))` from `spring-security-test`; the user name is the actor ID.
- Send JSON in `snake_case`, assert status, `$.data...` / `$.error.code` with `jsonPath`, and the database effect through `JdbcTemplate`.
- Assert published events with `@RecordApplicationEvents` and `ApplicationEvents`.
- Minimum per endpoint: success, validation failure (422 `validation_failed`), unauthenticated (401), each rejecting business rule with its error code, and that a rejected request changed nothing.
- Mock only the edges (external HTTP clients, mail) with `@MockitoBean` (`@MockBean` before Spring Boot 3.4). Never mock the service or a repository in an API test.

The complete example is `.claude/skills/new-endpoint/reference/src/test/java/com/example/app/modules/billing/controller/TransferApiTest.java.tpl`.

## Repository tests

- Custom queries with real logic (filters, locking, native SQL) get a `@DataJpaTest` with `@AutoConfigureTestDatabase(replace = NONE)` on PostgreSQL. Derived `findBy...` methods are covered by the API tests.
