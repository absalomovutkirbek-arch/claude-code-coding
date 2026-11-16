---
name: strategy
description: Scaffold a Strategy - one interface, one class per variant and a resolver. Use when the same job has 2 or more interchangeable implementations chosen at runtime, such as payment providers, pricing rules or export formats.
argument-hint: "[Module] [job] [variant1, variant2, ...]"
---

# Strategy

Build the strategy `$ARGUMENTS`.

## 1. Check the trigger first

Use a strategy only when 2 or more variants exist today (or the second is part of this task) and the variant is chosen at runtime from data. With a single variant, write the class directly behind an interface if it wraps an external system, and skip the resolver.

## 2. Files

```
app/Modules/<Module>/Enums/<Kind>.php                       the value the choice is made on
app/Modules/<Module>/Strategies/<Job>/
    <Job>Interface.php                                      named after the job
    <Variant><Job>.php                                      one class per variant
    <Job>Resolver.php                                       enum -> variant, the only switch
tests/Unit/Modules/<Module>/Strategies/<Job>/<Variant><Job>Test.php
```

## 3. Rules

- The interface describes the job in domain terms and uses DTOs. No provider-specific types leak through it.
- Every variant fully honours the interface. No "not supported" methods; if a variant cannot do something, the interface is too wide.
- The resolver is the only place that maps the enum to a class. No `if`/`switch`/`match` on the kind anywhere else in the codebase.
- The resolver receives the variants through its constructor and uses an exhaustive `match`, so a new enum case without a variant fails loudly.
- Adding a variant = one enum case + one class + one constructor argument and one `match` arm in the resolver. Nothing else changes.
- The service depends on the resolver, asks it for the variant and calls the interface.
- Variants that call external APIs do so through an injected client (`Illuminate\Http\Client\Factory` or a dedicated adapter), read credentials from an injected config value object, and translate provider errors into module exceptions.

## 4. Example (tested)

`app/Modules/Payment/Enums/PaymentMethod.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Enums;

enum PaymentMethod: string
{
    case Click = 'click';
    case Payme = 'payme';
}
```

`app/Modules/Payment/Strategies/Gateway/PaymentGatewayInterface.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Strategies\Gateway;

use App\Modules\Payment\Dto\ChargeDto;

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

`app/Modules/Payment/Strategies/Gateway/ClickPaymentGateway.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Strategies\Gateway;

use App\Modules\Payment\Dto\ChargeDto;

final class ClickPaymentGateway implements PaymentGatewayInterface
{
    public function charge(ChargeDto $charge): string
    {
        // Call the Click API through an injected HTTP client.
        return 'click-'.$charge->orderId;
    }
}
```

`app/Modules/Payment/Strategies/Gateway/PaymentGatewayResolver.php`

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Strategies\Gateway;

use App\Modules\Payment\Enums\PaymentMethod;

/**
 * The only place that maps a payment method to its gateway.
 */
final class PaymentGatewayResolver
{
    public function __construct(
        private readonly ClickPaymentGateway $click,
        private readonly PaymePaymentGateway $payme,
    ) {}

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
