---
name: pipeline
description: Scaffold a multi-step use case as a Pipeline (Chain of Responsibility) with one handler class per step. Use when a service method has 3 or more ordered steps, or steps that are reused or toggled.
argument-hint: "[Module] [use-case] [step1, step2, ...]"
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
app/Modules/<Module>/Services/<Usecase>Service.php          builds and runs the pipeline
app/Modules/<Module>/Services/Handlers/<Usecase>/
    <Usecase>Context.php                                    typed, shared state of the steps
    <Step>Handler.php                                       one class per step
tests/Unit/Modules/<Module>/Handlers/<Usecase>/<Step>HandlerTest.php
```

The runner is Laravel's `Illuminate\Pipeline\Pipeline`. `App\Core\Pipeline\HandlerInterface` comes from the shared kernel; if it is missing, run `/foundation` first.

## 3. Rules

- The context is created by the service from the DTO. The DTO is `readonly`; handlers write only to the context's own fields. Document which handler sets each field.
- A handler starts with `assert($context instanceof <Usecase>Context);`, does one step, then `return $next($context);`.
- A handler stops the chain by throwing a domain exception. Returning without calling `$next` is allowed only for a legitimate early finish (for example "already processed", idempotency).
- Handlers are stateless. Dependencies (repository interfaces, gateways) arrive through the constructor.
- The step order is declared once, in the service, top to bottom, as injected handler instances. Do not pass class-name strings or closures to `through()`.
- The service owns the transaction around the pipeline and dispatches events after it. Handlers never open transactions and never dispatch events.
- A handler that calls an external system does not belong inside the transaction. Split the use case: pipeline inside the transaction, external call after commit through an event or job.

## 4. Example (tested)

`app/Modules/Order/Services/Handlers/Checkout/CheckoutContext.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Order\Services\Handlers\Checkout;

use App\Modules\Order\Dto\CheckoutDto;

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

    public function __construct(public readonly CheckoutDto $dto) {}
}
```

`app/Modules/Order/Services/Handlers/Checkout/ValidateCartHandler.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Order\Services\Handlers\Checkout;

use App\Core\Pipeline\HandlerInterface;
use App\Modules\Order\Exceptions\EmptyCartException;
use Closure;

final class ValidateCartHandler implements HandlerInterface
{
    public function handle(object $context, Closure $next): object
    {
        assert($context instanceof CheckoutContext);

        if ($context->dto->items === []) {
            throw new EmptyCartException;
        }

        return $next($context);
    }
}
```

`app/Modules/Order/Services/Handlers/Checkout/CalculateTotalHandler.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Order\Services\Handlers\Checkout;

use App\Core\Pipeline\HandlerInterface;
use Closure;

final class CalculateTotalHandler implements HandlerInterface
{
    public function handle(object $context, Closure $next): object
    {
        assert($context instanceof CheckoutContext);

        foreach ($context->dto->items as $productId => $quantity) {
            $context->total += $context->prices[$productId] * $quantity;
        }

        return $next($context);
    }
}
```

`app/Modules/Order/Services/CheckoutService.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Order\Services;

use App\Core\Db\TransactionManagerInterface;
use App\Modules\Order\Dto\CheckoutDto;
use App\Modules\Order\Events\OrderPlaced;
use App\Modules\Order\Services\Handlers\Checkout\CalculateTotalHandler;
use App\Modules\Order\Services\Handlers\Checkout\CheckoutContext;
use App\Modules\Order\Services\Handlers\Checkout\CreateOrderHandler;
use App\Modules\Order\Services\Handlers\Checkout\LoadPricesHandler;
use App\Modules\Order\Services\Handlers\Checkout\ReserveStockHandler;
use App\Modules\Order\Services\Handlers\Checkout\ValidateCartHandler;
use Illuminate\Contracts\Events\Dispatcher;
use Illuminate\Pipeline\Pipeline;

final class CheckoutService
{
    public function __construct(
        private readonly Pipeline $pipeline,
        private readonly TransactionManagerInterface $transaction,
        private readonly Dispatcher $events,
        private readonly ValidateCartHandler $validateCart,
        private readonly LoadPricesHandler $loadPrices,
        private readonly ReserveStockHandler $reserveStock,
        private readonly CalculateTotalHandler $calculateTotal,
        private readonly CreateOrderHandler $createOrder,
    ) {}

    /**
     * @return int ID of the created order.
     */
    public function checkout(CheckoutDto $dto): int
    {
        $context = $this->transaction->run(fn (): CheckoutContext => $this->pipeline
            ->send(new CheckoutContext($dto))
            // The order of steps is declared here and nowhere else.
            ->through([
                $this->validateCart,
                $this->loadPrices,
                $this->reserveStock,
                $this->calculateTotal,
                $this->createOrder,
            ])
            ->thenReturn());

        $this->events->dispatch(new OrderPlaced($context->orderId));

        return $context->orderId;
    }
}
```

`LoadPricesHandler`, `ReserveStockHandler` and `CreateOrderHandler` follow the same shape and receive their repositories through the constructor.

## 5. Tests

- One unit test class per handler: given a context, assert what it changed and that `$next` was called; assert the exception when the step rejects.
- One service test that runs the real pipeline (`new Pipeline(new Container)`) with mocked repositories for the happy path.

```php
public function test_rejects_empty_cart(): void
{
    $context = new CheckoutContext(new CheckoutDto(customerId: 1, items: []));

    $this->expectException(EmptyCartException::class);

    (new ValidateCartHandler)->handle($context, static fn (object $c): object => $c);
}
```
