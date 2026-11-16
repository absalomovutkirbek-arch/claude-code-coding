package com.example.app.modules.billing.dto;

import com.example.app.modules.billing.enums.TransferStatus;

/**
 * @param status optional filter
 * @param page 1-based
 */
public record TransferFilterDto(long initiatorId, TransferStatus status, int page, int perPage) {
}
