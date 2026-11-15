package com.example.app.core.exception;

import java.util.Map;

/** A business rule rejected the request. Rendered as 422. Module exceptions extend this and override errorCode(). */
public class BusinessRuleException extends DomainException {

    public BusinessRuleException(String message) {
        super(message);
    }

    public BusinessRuleException(String message, Map<String, Object> details) {
        super(message, details);
    }

    @Override
    public String errorCode() {
        return "business_rule_violated";
    }
}
