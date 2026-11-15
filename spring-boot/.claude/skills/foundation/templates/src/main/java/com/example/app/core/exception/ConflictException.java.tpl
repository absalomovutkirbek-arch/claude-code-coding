package com.example.app.core.exception;

import java.util.Map;

/** The request conflicts with the current state (duplicate, concurrent change). Rendered as 409. */
public class ConflictException extends DomainException {

    public ConflictException(String message) {
        super(message);
    }

    public ConflictException(String message, Map<String, Object> details) {
        super(message, details);
    }

    @Override
    public String errorCode() {
        return "conflict";
    }
}
