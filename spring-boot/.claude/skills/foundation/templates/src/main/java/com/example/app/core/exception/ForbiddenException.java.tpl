package com.example.app.core.exception;

import java.util.Map;

/** The caller is authenticated but may not do this. Rendered as 403. */
public class ForbiddenException extends DomainException {

    public ForbiddenException(String message) {
        super(message);
    }

    public ForbiddenException(String message, Map<String, Object> details) {
        super(message, details);
    }

    @Override
    public String errorCode() {
        return "forbidden";
    }
}
