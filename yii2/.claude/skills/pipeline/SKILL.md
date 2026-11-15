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
modules/<module>/services/<Usecase>Service.php            builds and runs the pipeline
modules/<module>/services/handlers/<usecase>/
    <Usecase>Context.php                                  typed, shared state of the steps
    <Step>Handler.php                                     one class per step
tests/unit/modules/<module>/handlers/<usecase>/<Step>HandlerTest.php
```

`app\core\pipeline\Pipeline` and `HandlerInterface` come from the shared kernel. If `core/pipeline/` is missing, run `/foundation` first.

## 3. Rules

- The context is created by the service from the DTO. The DTO is `readonly`; handlers write only to the context's own fields. Document which handler sets each field.
- A handler starts with `assert($context instanceof <Usecase>Context);`, does one step, then `return $next($context);`.
- A handler stops the chain by throwing a domain exception. Returning without calling `$next` is allowed only for a legitimate early finish (for example "already processed", idempotency).
- Handlers are stateless. Dependencies (repository interfaces, gateways) arrive through the constructor.
- The step order is declared once, in the service, top to bottom.
- The service owns the transaction around `process()` and dispatches events after it. Handlers never open transactions and never dispatch events.
- A handler that calls an external system does not belong inside the transaction. Split the use case: pipeline inside the transaction, external call after commit through an event or job.

## 4. Example (tested)

`modules/order/services/handlers/checkout/CheckoutContext.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\order\services\handlers\checkout;

use app\modules\order\dto\CheckoutDto;

/**
 * Everything the checkout steps share. Created by CheckoutService, filled by the handlers.
 */
final class CheckoutContext
{
    /** @var array<int, int> Product ID => unit price in minor units. Set by LoadPricesHandler. */
    public array $prices = [];

    /** Minor units. Set by CalculateTotalHandler. */
    public int $total = 0;

    /** Set by CreateOrderHandler. */
    public ?int $orderId = null;

    public function __construct(public readonly CheckoutDto $dto)
    {
    }
}
```

`modules/order/services/handlers/checkout/ValidateCartHandler.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\order\services\handlers\checkout;

use app\core\pipeline\HandlerInterface;
use app\modules\order\exceptions\EmptyCartException;

final class ValidateCartHandler implements HandlerInterface
{
    public function handle(object $context, callable $next): object
    {
        assert($context instanceof CheckoutContext);

        if ($context->dto->items === []) {
            throw new EmptyCartException();
        }

        return $next($context);
    }
}
```

`modules/order/services/handlers/checkout/CalculateTotalHandler.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\order\services\handlers\checkout;

use app\core\pipeline\HandlerInterface;

final class CalculateTotalHandler implements HandlerInterface
{
    public function handle(object $context, callable $next): object
    {
        assert($context instanceof CheckoutContext);

        foreach ($context->dto->items as $productId => $quantity) {
            $context->total += $context->prices[$productId] * $quantity;
        }

        return $next($context);
    }
}
```

`modules/order/services/CheckoutService.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\order\services;

use app\core\db\TransactionManagerInterface;
use app\core\events\EventDispatcherInterface;
use app\core\pipeline\Pipeline;
use app\modules\order\dto\CheckoutDto;
use app\modules\order\events\OrderPlaced;
use app\modules\order\services\handlers\checkout\CalculateTotalHandler;
use app\modules\order\services\handlers\checkout\CheckoutContext;
use app\modules\order\services\handlers\checkout\CreateOrderHandler;
use app\modules\order\services\handlers\checkout\LoadPricesHandler;
use app\modules\order\services\handlers\checkout\ReserveStockHandler;
use app\modules\order\services\handlers\checkout\ValidateCartHandler;

final class CheckoutService
{
    public function __construct(
        private readonly TransactionManagerInterface $transaction,
        private readonly EventDispatcherInterface $events,
        private readonly ValidateCartHandler $validateCart,
        private readonly LoadPricesHandler $loadPrices,
        private readonly ReserveStockHandler $reserveStock,
        private readonly CalculateTotalHandler $calculateTotal,
        private readonly CreateOrderHandler $createOrder,
    ) {
    }

    /**
     * @return int ID of the created order.
     */
    public function checkout(CheckoutDto $dto): int
    {
        // The order of steps is declared here and nowhere else.
        $pipeline = new Pipeline(
            $this->validateCart,
            $this->loadPrices,
            $this->reserveStock,
            $this->calculateTotal,
            $this->createOrder,
        );

        $context = $this->transaction->run(
            static fn (): CheckoutContext => $pipeline->process(new CheckoutContext($dto)),
        );

        $this->events->dispatch(new OrderPlaced($context->orderId));

        return $context->orderId;
    }
}
```

`LoadPricesHandler`, `ReserveStockHandler` and `CreateOrderHandler` follow the same shape and receive their repositories through the constructor.

## 5. Tests

- One unit test class per handler: given a context, assert what it changed and that `$next` was called; assert the exception when the step rejects.
- One service test that runs the real pipeline with mocked repositories for the happy path.

```php
public function test_rejects_empty_cart(): void
{
    $context = new CheckoutContext(new CheckoutDto(customerId: 1, items: []));

    $this->expectException(EmptyCartException::class);

    (new ValidateCartHandler())->handle($context, static fn (object $c): object => $c);
}
```
