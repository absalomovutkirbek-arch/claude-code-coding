package com.example.app.core.api;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import org.springframework.data.domain.Page;

/**
 * The only success envelope: {@code {"data": ..., "meta": {...}}}.
 *
 * @param data a response record or a list of them, never an entity
 * @param meta pagination or other metadata; an empty object when there is none
 */
public record ApiResponse<T>(T data, Object meta) {

    public static <T> ApiResponse<T> of(T data) {
        return new ApiResponse<>(data, Map.of());
    }

    public static <E, R> ApiResponse<List<R>> page(Page<E> page, Function<E, R> mapper) {
        return new ApiResponse<>(page.getContent().stream().map(mapper).toList(), PageMeta.of(page));
    }
}
