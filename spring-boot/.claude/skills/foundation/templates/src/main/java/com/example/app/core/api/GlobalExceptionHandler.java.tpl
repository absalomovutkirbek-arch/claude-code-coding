package com.example.app.core.api;

import com.example.app.core.exception.ConflictException;
import com.example.app.core.exception.DomainException;
import com.example.app.core.exception.ForbiddenException;
import com.example.app.core.exception.NotFoundException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.MessageSourceResolvable;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/**
 * The single place where exceptions become HTTP responses.
 *
 * <p>Controllers and services never catch exceptions to build an error response and never return
 * {@code ResponseEntity} with an error body.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private static final String VALIDATION_FAILED = "validation_failed";
    private static final String VALIDATION_MESSAGE = "The given data is invalid.";

    private static final Map<Integer, String> HTTP_CODES = Map.ofEntries(
            Map.entry(400, "bad_request"),
            Map.entry(401, "unauthorized"),
            Map.entry(403, "forbidden"),
            Map.entry(404, "not_found"),
            Map.entry(405, "method_not_allowed"),
            Map.entry(406, "not_acceptable"),
            Map.entry(409, "conflict"),
            Map.entry(415, "unsupported_media_type"),
            Map.entry(422, "unprocessable_entity"),
            Map.entry(429, "too_many_requests"),
            Map.entry(503, "service_unavailable"));

    @ExceptionHandler(DomainException.class)
    public ResponseEntity<ApiError> handleDomain(DomainException exception) {
        HttpStatus status = switch (exception) {
            case NotFoundException e -> HttpStatus.NOT_FOUND;
            case ForbiddenException e -> HttpStatus.FORBIDDEN;
            case ConflictException e -> HttpStatus.CONFLICT;
            default -> HttpStatus.UNPROCESSABLE_ENTITY;
        };

        return respond(status, ApiError.of(exception.errorCode(), exception.getMessage(), exception.details()));
    }

    /** Body ({@code @Valid @RequestBody}) and query object ({@code @Valid} record) validation. */
    @ExceptionHandler(BindException.class)
    public ResponseEntity<ApiError> handleBinding(BindException exception) {
        Map<String, List<String>> details = new LinkedHashMap<>();
        for (FieldError error : exception.getFieldErrors()) {
            String message = error.isBindingFailure() ? "The value has an invalid format." : error.getDefaultMessage();
            add(details, error.getField(), message);
        }
        exception.getGlobalErrors().forEach(error -> add(details, "_", error.getDefaultMessage()));

        return validationFailed(details);
    }

    /** Constraints declared directly on controller method parameters. */
    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ApiError> handleMethodValidation(HandlerMethodValidationException exception) {
        Map<String, List<String>> details = new LinkedHashMap<>();
        exception.getParameterValidationResults().forEach(result -> {
            String name = result.getMethodParameter().getParameterName();
            for (MessageSourceResolvable error : result.getResolvableErrors()) {
                String field = error instanceof FieldError fieldError ? fieldError.getField() : name;
                add(details, field, error.getDefaultMessage());
            }
        });

        return validationFailed(details);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiError> handleConstraintViolation(ConstraintViolationException exception) {
        Map<String, List<String>> details = new LinkedHashMap<>();
        for (ConstraintViolation<?> violation : exception.getConstraintViolations()) {
            String path = violation.getPropertyPath().toString();
            add(details, path.substring(path.lastIndexOf('.') + 1), violation.getMessage());
        }

        return validationFailed(details);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiError> handleTypeMismatch(MethodArgumentTypeMismatchException exception) {
        return validationFailed(Map.of(snakeCase(exception.getName()), List.of("The value has an invalid format.")));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiError> handleMissingParameter(MissingServletRequestParameterException exception) {
        return validationFailed(Map.of(snakeCase(exception.getParameterName()), List.of("The parameter is required.")));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiError> handleUnreadableBody(HttpMessageNotReadableException exception) {
        return respond(HttpStatus.BAD_REQUEST, ApiError.of("bad_request", "The request body is missing or malformed."));
    }

    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ResponseEntity<ApiError> handleOptimisticLock(OptimisticLockingFailureException exception) {
        return respond(HttpStatus.CONFLICT,
                ApiError.of("conflict", "The record was changed by another request. Reload and try again."));
    }

    /** Thrown by method security ({@code @PreAuthorize}) inside controllers. */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiError> handleAccessDenied(AccessDeniedException exception) {
        return respond(HttpStatus.FORBIDDEN, ApiError.of("forbidden", "You are not allowed to do this."));
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiError> handleAuthentication(AuthenticationException exception) {
        return respond(HttpStatus.UNAUTHORIZED, ApiError.of("unauthorized", "Authentication is required."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleOther(Exception exception) {
        // Framework exceptions that carry their own status: unknown route, wrong verb, unsupported media type.
        if (exception instanceof ErrorResponse errorResponse) {
            HttpStatusCode status = errorResponse.getStatusCode();
            String code = HTTP_CODES.getOrDefault(status.value(), "http_error");
            String message = Character.toUpperCase(code.charAt(0)) + code.substring(1).replace('_', ' ') + ".";

            return ResponseEntity.status(status).headers(errorResponse.getHeaders()).body(ApiError.of(code, message));
        }

        log.error("Unhandled exception", exception);

        return respond(HttpStatus.INTERNAL_SERVER_ERROR, ApiError.of("internal_error", "Internal server error."));
    }

    private static ResponseEntity<ApiError> validationFailed(Map<String, List<String>> details) {
        return respond(HttpStatus.UNPROCESSABLE_ENTITY, ApiError.of(VALIDATION_FAILED, VALIDATION_MESSAGE, details));
    }

    private static ResponseEntity<ApiError> respond(HttpStatus status, ApiError error) {
        return ResponseEntity.status(status).body(error);
    }

    private static void add(Map<String, List<String>> details, String field, String message) {
        details.computeIfAbsent(snakeCase(field), key -> new ArrayList<>()).add(message);
    }

    /** Field names in errors use the same casing as the JSON API. */
    private static String snakeCase(String name) {
        return name.replaceAll("([a-z0-9])([A-Z])", "$1_$2").toLowerCase();
    }
}
