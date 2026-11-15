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
modules/<module>/enums/<Kind>.java                          the value the choice is made on
modules/<module>/strategy/<job>/
    <Job>.java                                              interface named after the job
    <Variant><Job>.java                                     one @Component per variant
    <Job>Resolver.java                                      enum -> variant, the only mapping
src/test/java/.../modules/<module>/strategy/<job>/<Variant><Job>Test.java
```

## 3. Rules

- The interface describes the job in domain terms and uses records. No provider-specific types leak through it.
- Every variant fully honours the interface and declares which enum constant it serves. No "not supported" methods; if a variant cannot do something, the interface is too wide.
- The resolver is the only place that maps the enum to a variant. No `if`/`switch` on the kind anywhere else in the codebase.
- The resolver receives all variants as `List<<Job>>` and checks at startup that every enum constant has exactly one variant, so a new constant without a variant stops the application from starting instead of failing in production.
- Adding a variant = one enum constant + one `@Component` class. Nothing else changes.
- The service depends on the resolver, asks it for the variant and calls the interface.
- Variants that call external APIs do so through an injected client (`RestClient` or a dedicated adapter), take credentials from `@ConfigurationProperties`, and translate provider errors into module exceptions.

## 4. Example (tested)

`modules/payment/enums/PaymentMethod.java`

```java
package com.example.app.modules.payment.enums;

import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Locale;

public enum PaymentMethod {
    CLICK,
    PAYME;

    @JsonValue
    public String value() {
        return name().toLowerCase(Locale.ROOT);
    }
}
```

`modules/payment/strategy/gateway/PaymentGateway.java`

```java
package com.example.app.modules.payment.strategy.gateway;

import com.example.app.modules.payment.dto.ChargeDto;
import com.example.app.modules.payment.enums.PaymentMethod;

public interface PaymentGateway {

    /** The payment method this variant serves. */
    PaymentMethod method();

    /**
     * Starts a payment at the provider.
     *
     * @return provider transaction ID
     */
    String charge(ChargeDto charge);
}
```

`modules/payment/strategy/gateway/ClickPaymentGateway.java`

```java
package com.example.app.modules.payment.strategy.gateway;

import com.example.app.modules.payment.dto.ChargeDto;
import com.example.app.modules.payment.enums.PaymentMethod;
import org.springframework.stereotype.Component;

@Component
public class ClickPaymentGateway implements PaymentGateway {

    @Override
    public PaymentMethod method() {
        return PaymentMethod.CLICK;
    }

    @Override
    public String charge(ChargeDto charge) {
        // Call the Click API through an injected client.
        return "click-" + charge.orderId();
    }
}
```

`modules/payment/strategy/gateway/PaymentGatewayResolver.java`

```java
package com.example.app.modules.payment.strategy.gateway;

import com.example.app.modules.payment.enums.PaymentMethod;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

/**
 * The only place that maps a payment method to its gateway.
 */
@Component
public class PaymentGatewayResolver {

    private final Map<PaymentMethod, PaymentGateway> gateways = new EnumMap<>(PaymentMethod.class);

    public PaymentGatewayResolver(List<PaymentGateway> variants) {
        for (PaymentGateway variant : variants) {
            if (gateways.put(variant.method(), variant) != null) {
                throw new IllegalStateException("Two payment gateways registered for " + variant.method());
            }
        }
        for (PaymentMethod method : PaymentMethod.values()) {
            if (!gateways.containsKey(method)) {
                throw new IllegalStateException("No payment gateway registered for " + method);
            }
        }
    }

    public PaymentGateway resolve(PaymentMethod method) {
        return gateways.get(method);
    }
}
```

Usage in a service:

```java
String transactionId = gateways.resolve(dto.method())
        .charge(new ChargeDto(order.getId(), order.getTotal(), order.getCurrency()));
```

## 5. Tests

- One test class per variant covering the shared contract and the variant's own behaviour.
- One resolver test: built with all variants it resolves every `PaymentMethod.values()`; built with one variant missing it throws `IllegalStateException`.
