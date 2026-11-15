package com.example.app.core.pipeline;

/**
 * One step of a use case run through a {@link Pipeline} (Chain of Responsibility).
 *
 * <p>A handler does its single step on the shared context and passes it on:
 * {@code return next.proceed(context);}. It stops the chain by throwing a domain exception.
 *
 * @param <C> the context type shared by the steps of one use case
 */
@FunctionalInterface
public interface Handler<C> {

    C handle(C context, Next<C> next);

    /** The rest of the chain. */
    @FunctionalInterface
    interface Next<C> {

        C proceed(C context);
    }
}
