package com.example.app.core.api;

import org.springframework.data.domain.Page;

/** Pagination metadata of a list response. {@code page} is 1-based. */
public record PageMeta(int page, int perPage, long total, int totalPages) {

    public static PageMeta of(Page<?> page) {
        return new PageMeta(page.getNumber() + 1, page.getSize(), page.getTotalElements(), page.getTotalPages());
    }
}
