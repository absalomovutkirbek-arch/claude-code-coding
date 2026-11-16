---
paths:
  - "**/controller/**/*.java"
  - "**/request/**/*.java"
  - "**/response/**/*.java"
---

# Spring Boot: HTTP layer (controllers, requests, responses)

## Controller

```java
@RestController
@RequestMapping("/api/v1/billing/transfers")
public class TransferController {

    private final TransferService service;

    public TransferController(TransferService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TransferResponse> create(@Valid @RequestBody CreateTransferRequest request,
            @ActorId long actorId) {
        return ApiResponse.of(TransferResponse.from(service.create(request.toDto(actorId))));
    }

    @GetMapping("/{id:\\d+}")
    public ApiResponse<TransferResponse> view(@PathVariable long id, @ActorId long actorId) {
        return ApiResponse.of(TransferResponse.from(service.getForActor(id, actorId)));
    }

    @GetMapping
    public ApiResponse<List<TransferResponse>> list(@Valid ListTransfersRequest request, @ActorId long actorId) {
        return ApiResponse.page(service.list(request.toDto(actorId)), TransferResponse::from);
    }
}
```

- One controller per resource. Standard method names: `list`, `view`, `create`, `update`, `delete`; custom operations use the verb (`cancel`, `approve`).
- A handler method has at most three steps: build the DTO, call one service method, wrap the result. If it needs an `if`, a loop or a second service call, that logic belongs in the service.
- A controller injects services only. Never a repository, `EntityManager` or `JdbcTemplate`.
- Body input: `@Valid @RequestBody <Request>`. Query input: `@Valid <Request>` record without annotation. IDs: `@PathVariable long id` with the `{id:\\d+}` pattern so that a non-numeric ID is a 404.
- The authenticated user: `@ActorId long actorId`. Never `Principal`, `Authentication` or `SecurityContextHolder` in handler methods.
- Return type is always `ApiResponse<...>`: `ApiResponse.of(response)`, `ApiResponse.page(page, Response::from)`. Status codes other than 200 through `@ResponseStatus` (201 for create, 204 with `void` for delete).
- No `try/catch`, no `ResponseEntity`, no `@ExceptionHandler` in controllers. `GlobalExceptionHandler` renders every exception.
- Role checks use `@PreAuthorize` on the handler method. Record-level ownership is a business rule and lives in the service.

## Request (form)

```java
public record CreateTransferRequest(
        @NotNull @Positive Long fromWalletId,
        @NotNull @Positive Long toWalletId,
        @NotNull @Positive Long amount) {

    public CreateTransferDto toDto(long actorId) {
        return new CreateTransferDto(actorId, fromWalletId, toWalletId, amount);
    }
}
```

- One record per endpoint that accepts input. Name: `<Verb><Entity>Request`.
- Components use wrapper types (`Long`, `Integer`, `Boolean`) so that a missing value fails `@NotNull` instead of becoming `0`.
- Annotations cover format only: `@NotNull`, `@NotBlank`, `@Size`, `@Positive`, `@Min`/`@Max`, `@Email`, `@Pattern`, `@Valid` on nested records and `List<@Valid Item>`.
- Cross-field format checks are `@AssertTrue` methods named after the field the error belongs to: `isToWalletId()` reports under `to_wallet_id`.
- Query records name multi-word parameters with `@BindParam("per_page")`, because the Jackson naming strategy does not apply to query strings. Defaults are applied in `toDto()`.
- `toDto(long actorId)` is the only way a DTO is created from HTTP input. A request holds no business rules and never touches a repository.

## Response (resource)

- `record <Entity>Response` with `static <Entity>Response from(<Entity> entity)`. List every field explicitly.
- Enums are returned as the enum type (their `@JsonValue` writes lowercase). Timestamps are `Instant` truncated to seconds: `getCreatedAt().truncatedTo(ChronoUnit.SECONDS)`.
- Nested data is mapped from associations the service already loaded. A response never triggers a query; with `open-in-view=false` a lazy association outside the transaction throws.
- Never return an entity, a `Page`, a `Map` or a JPA projection from a controller.

## Errors

- Validation failures are rendered as 422 `validation_failed` with `snake_case` field names in `error.details`. Malformed JSON is 400 `bad_request`.
- A missing route, wrong verb, unauthenticated or forbidden request already produces the standard error envelope. Do not add per-endpoint handling.
