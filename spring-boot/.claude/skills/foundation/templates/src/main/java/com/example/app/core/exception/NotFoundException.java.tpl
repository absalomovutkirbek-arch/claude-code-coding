package com.example.app.core.exception;

import java.util.Map;

/** The record does not exist, or the caller must not learn that it exists. Rendered as 404. */
public class NotFoundException extends DomainException {

    public NotFoundException(String message) {
        super(message);
    }

    public NotFoundException(String message, Map<String, Object> details) {
        super(message, details);
    }

    @Override
    public String errorCode() {
        return "not_found";
    }
}
