package com.example.app.modules.billing.request;

import com.example.app.modules.billing.dto.TransferFilterDto;
import com.example.app.modules.billing.enums.TransferStatus;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.web.bind.annotation.BindParam;

/**
 * Query parameters of GET /api/v1/billing/transfers.
 */
public record ListTransfersRequest(
        TransferStatus status,
        @Min(1) Integer page,
        @BindParam("per_page") @Min(1) @Max(100) Integer perPage) {

    private static final int DEFAULT_PER_PAGE = 20;

    public TransferFilterDto toDto(long actorId) {
        return new TransferFilterDto(
                actorId,
                status,
                page == null ? 1 : page,
                perPage == null ? DEFAULT_PER_PAGE : perPage);
    }
}
