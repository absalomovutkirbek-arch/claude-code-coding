package com.example.app.core.pipeline;

import java.util.List;

/**
 * Runs handlers in the declared order. Built by the service that owns the use case.
 *
 * <pre>{@code
 * CheckoutContext context = Pipeline.of(validateCart, loadPrices, createOrder).process(new CheckoutContext(dto));
 * }</pre>
 */
public final class Pipeline<C> {

    private final List<Handler<C>> handlers;

    private Pipeline(List<Handler<C>> handlers) {
        this.handlers = handlers;
    }

    @SafeVarargs
    public static <C> Pipeline<C> of(Handler<C>... handlers) {
        return new Pipeline<>(List.of(handlers));
    }

    public C process(C context) {
        return invoke(0, context);
    }

    private C invoke(int index, C context) {
        if (index == handlers.size()) {
            return context;
        }

        return handlers.get(index).handle(context, next -> invoke(index + 1, next));
    }
}
