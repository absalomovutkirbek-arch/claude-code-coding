---
name: pipeline
description: Scaffold a multi-step use case as a Pipeline (Chain of Responsibility) with one handler class per step. Use when a service method has 3 or more ordered steps, or steps that are reused or toggled.
argument-hint: "[module] [use-case] [step1, step2, ...]"
---

# Pipeline (Chain of Responsibility)

Build the use case `$ARGUMENTS` as a pipeline.

## 1. Check the trigger first

Use a pipeline only when at least one is true:

- the use case has 3 or more ordered steps;
- a step is reused by another use case;
- steps are added, removed or reordered per case (per tenant, per order type).

With 1-2 steps, write private methods in the service and stop. Tell the developer why no pipeline was created.

## 2. Files

```
modules/<module>/service/<Usecase>Service.java              builds and runs the pipeline
modules/<module>/service/handler/<usecase>/
    <Usecase>Context.java                                   typed, shared state of the steps
    <Step>Handler.java                                      one class per step
src/test/java/.../modules/<module>/service/handler/<usecase>/<Step>HandlerTest.java
```

`Pipeline` and `Handler` come from `<base>.core.pipeline`. If they are missing, run `/foundation` first.

## 3. Rules

- The context is created by the service from the DTO. The DTO is an immutable record; handlers write only to the context's own fields through its methods. Document which handler sets each field.
- A handler does one step, then `return next.proceed(context);`.
- A handler stops the chain by throwing a domain exception. Returning without calling `next` is allowed only for a legitimate early finish (for example "already processed", idempotency).
- Handlers are stateless `@Component` classes. Dependencies (repositories, gateways) arrive through the constructor.
- The step order is declared once, in the service, top to bottom. Do not inject `List<Handler<...>>` and rely on `@Order`.
- The service method is `@Transactional` and publishes the event. Handlers never carry `@Transactional` and never publish events.
- A handler that calls an external system does not belong inside the transaction. Split the use case: pipeline inside the transaction, external call after commit through an event listener.

## 4. Example (tested)

`modules/order/service/handler/checkout/CheckoutContext.java`

```java
package com.example.app.modules.order.service.handler.checkout;

import com.example.app.modules.order.dto.CheckoutDto;
import java.util.HashMap;
import java.util.Map;

/**
 * Everything the checkout steps share. Created by CheckoutService, filled by the handlers.
 */
public final class CheckoutContext {

    private final CheckoutDto dto;

    /** Product ID -> unit price in minor units. Filled by LoadPricesHandler. */
    private final Map<Long, Long> prices = new HashMap<>();

    /** Minor units. Set by CalculateTotalHandler. */
    private long total;

    /** Set by CreateOrderHandler. */
    private Long orderId;

    public CheckoutContext(CheckoutDto dto) {
        this.dto = dto;
    }

    public CheckoutDto dto() {
        return dto;
    }

    public Map<Long, Long> prices() {
        return prices;
    }

    public long total() {
        return total;
    }

    public void addToTotal(long amount) {
        total += amount;
    }

    public Long orderId() {
        return orderId;
    }

    public void orderCreated(long id) {
        orderId = id;
    }
}
```

`modules/order/service/handler/checkout/ValidateCartHandler.java`

```java
package com.example.app.modules.order.service.handler.checkout;

import com.example.app.core.pipeline.Handler;
import com.example.app.modules.order.exception.EmptyCartException;
import org.springframework.stereotype.Component;

@Component
public class ValidateCartHandler implements Handler<CheckoutContext> {

    @Override
    public CheckoutContext handle(CheckoutContext context, Next<CheckoutContext> next) {
        if (context.dto().items().isEmpty()) {
            throw new EmptyCartException();
        }

        return next.proceed(context);
    }
}
```

`modules/order/service/handler/checkout/CalculateTotalHandler.java`

```java
package com.example.app.modules.order.service.handler.checkout;

import com.example.app.core.pipeline.Handler;
import org.springframework.stereotype.Component;

@Component
public class CalculateTotalHandler implements Handler<CheckoutContext> {

    @Override
    public CheckoutContext handle(CheckoutContext context, Next<CheckoutContext> next) {
        context.dto().items().forEach(
                (productId, quantity) -> context.addToTotal(context.prices().get(productId) * quantity));

        return next.proceed(context);
    }
}
```

`modules/order/service/CheckoutService.java`

```java
package com.example.app.modules.order.service;

import com.example.app.core.pipeline.Pipeline;
import com.example.app.modules.order.dto.CheckoutDto;
import com.example.app.modules.order.event.OrderPlaced;
import com.example.app.modules.order.service.handler.checkout.CalculateTotalHandler;
import com.example.app.modules.order.service.handler.checkout.CheckoutContext;
import com.example.app.modules.order.service.handler.checkout.CreateOrderHandler;
import com.example.app.modules.order.service.handler.checkout.LoadPricesHandler;
import com.example.app.modules.order.service.handler.checkout.ReserveStockHandler;
import com.example.app.modules.order.service.handler.checkout.ValidateCartHandler;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CheckoutService {

    private final Pipeline<CheckoutContext> pipeline;
    private final ApplicationEventPublisher events;

    public CheckoutService(
            ValidateCartHandler validateCart,
            LoadPricesHandler loadPrices,
            ReserveStockHandler reserveStock,
            CalculateTotalHandler calculateTotal,
            CreateOrderHandler createOrder,
            ApplicationEventPublisher events) {
        // The order of steps is declared here and nowhere else.
        this.pipeline = Pipeline.of(validateCart, loadPrices, reserveStock, calculateTotal, createOrder);
        this.events = events;
    }

    /**
     * @return ID of the created order
     */
    @Transactional
    public long checkout(CheckoutDto dto) {
        CheckoutContext context = pipeline.process(new CheckoutContext(dto));

        events.publishEvent(new OrderPlaced(context.orderId()));

        return context.orderId();
    }
}
```

`LoadPricesHandler`, `ReserveStockHandler` and `CreateOrderHandler` follow the same shape and receive their repositories through the constructor.

## 5. Tests

- One unit test class per handler: given a context, assert what it changed and that `next` was called; assert the exception when the step rejects.
- One service test that runs the real pipeline with mocked repositories for the happy path.

```java
@Test
void handle_rejectsEmptyCart() {
    CheckoutContext context = new CheckoutContext(new CheckoutDto(1, Map.of()));

    assertThatThrownBy(() -> new ValidateCartHandler().handle(context, next -> next))
            .isInstanceOf(EmptyCartException.class);
}
```
