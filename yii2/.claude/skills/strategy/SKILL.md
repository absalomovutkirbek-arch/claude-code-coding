---
name: strategy
description: Scaffold a Strategy - one interface, one class per variant and a resolver. Use when the same job has 2 or more interchangeable implementations chosen at runtime, such as payment providers, pricing rules or export formats.
argument-hint: "[module] [job] [variant1, variant2, ...]"
---

# Strategy

Build the strategy `$ARGUMENTS`.

## 1. Check the trigger first

Use a strategy only when 2 or more variants exist today (or the second is part of this task) and the variant is chosen at runtime from data. With a single variant, write the class directly behind an interface if it wraps an external system, and skip the resolver.

## 2. Files

```
modules/<module>/enums/<Kind>.php                         the value the choice is made on
modules/<module>/strategies/<job>/
    <Job>Interface.php                                    named after the job
    <Variant><Job>.php                                    one class per variant
    <Job>Resolver.php                                     enum -> variant, the only switch
tests/unit/modules/<module>/strategies/<job>/<Variant><Job>Test.php
```

## 3. Rules

- The interface describes the job in domain terms and uses DTOs. No provider-specific types leak through it.
- Every variant fully honours the interface. No "not supported" methods; if a variant cannot do something, the interface is too wide.
- The resolver is the only place that maps the enum to a class. No `if`/`switch`/`match` on the kind anywhere else in the codebase.
- The resolver receives the variants through its constructor and uses an exhaustive `match`, so a new enum case without a variant fails loudly.
- Adding a variant = one enum case + one class + one constructor argument and one `match` arm in the resolver. Nothing else changes.
- The service depends on the resolver, asks it for the variant and calls the interface.
- Variants that call external APIs do so through an injected HTTP client adapter and translate provider errors into module exceptions.

## 4. Example (tested)

`modules/payment/enums/PaymentMethod.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\payment\enums;

enum PaymentMethod: string
{
    case Click = 'click';
    case Payme = 'payme';
}
```

`modules/payment/strategies/gateway/PaymentGatewayInterface.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\payment\strategies\gateway;

use app\modules\payment\dto\ChargeDto;

interface PaymentGatewayInterface
{
    /**
     * Starts a payment at the provider.
     *
     * @return string Provider transaction ID.
     */
    public function charge(ChargeDto $charge): string;
}
```

`modules/payment/strategies/gateway/ClickPaymentGateway.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\payment\strategies\gateway;

use app\modules\payment\dto\ChargeDto;

final class ClickPaymentGateway implements PaymentGatewayInterface
{
    public function charge(ChargeDto $charge): string
    {
        // Call the Click API through an injected HTTP client adapter.
        return 'click-' . $charge->orderId;
    }
}
```

`modules/payment/strategies/gateway/PaymentGatewayResolver.php`

```php
<?php

declare(strict_types=1);

namespace app\modules\payment\strategies\gateway;

use app\modules\payment\enums\PaymentMethod;

/**
 * The only place that maps a payment method to its gateway.
 */
final class PaymentGatewayResolver
{
    public function __construct(
        private readonly ClickPaymentGateway $click,
        private readonly PaymePaymentGateway $payme,
    ) {
    }

    public function resolve(PaymentMethod $method): PaymentGatewayInterface
    {
        return match ($method) {
            PaymentMethod::Click => $this->click,
            PaymentMethod::Payme => $this->payme,
        };
    }
}
```

Usage in a service:

```php
$transactionId = $this->gateways->resolve($dto->method)->charge(
    new ChargeDto(orderId: $order->id, amount: $order->total, currency: $order->currency),
);
```

## 5. Tests

- One test class per variant covering the shared contract and the variant's own behaviour.
- One resolver test asserting that every enum case resolves: loop over `PaymentMethod::cases()`.
