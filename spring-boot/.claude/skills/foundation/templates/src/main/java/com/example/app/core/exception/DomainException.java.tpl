package com.example.app.core.exception;

import java.util.Map;

/**
 * Base class for every expected, business-level failure.
 *
 * <p>Domain exceptions know nothing about HTTP. {@code GlobalExceptionHandler} maps them to status codes.
 */
public abstract class DomainException extends RuntimeException {

    private final Map<String, Object> details;

    /**
     * @param message safe to show to the API consumer
     * @param details structured context returned as {@code error.details}
     */
    protected DomainException(String message, Map<String, Object> details) {
        super(message);
        this.details = Map.copyOf(details);
    }

    protected DomainException(String message) {
        this(message, Map.of());
    }

    /** Stable machine-readable code returned as {@code error.code}. Override in module exceptions. */
    public abstract String errorCode();

    public Map<String, Object> details() {
        return details;
    }
}
