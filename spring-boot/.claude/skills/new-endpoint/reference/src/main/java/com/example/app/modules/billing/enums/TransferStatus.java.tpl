package com.example.app.modules.billing.enums;

import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Locale;

/**
 * Stored in the database by constant name; written to the API in lowercase.
 */
public enum TransferStatus {
    COMPLETED,
    REVERSED;

    @JsonValue
    public String value() {
        return name().toLowerCase(Locale.ROOT);
    }
}
