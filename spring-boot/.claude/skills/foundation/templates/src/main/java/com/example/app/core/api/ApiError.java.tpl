package com.example.app.core.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.Map;

/**
 * The only error envelope: {@code {"error": {"code", "message", "details"}}}.
 */
public record ApiError(Body error) {

    public record Body(String code, String message, @JsonInclude(JsonInclude.Include.NON_EMPTY) Map<String, ?> details) {
    }

    public static ApiError of(String code, String message) {
        return new ApiError(new Body(code, message, Map.of()));
    }

    public static ApiError of(String code, String message, Map<String, ?> details) {
        return new ApiError(new Body(code, message, details));
    }
}
