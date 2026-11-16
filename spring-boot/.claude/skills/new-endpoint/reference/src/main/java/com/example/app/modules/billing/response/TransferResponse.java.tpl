package com.example.app.modules.billing.response;

import com.example.app.modules.billing.entity.Transfer;
import com.example.app.modules.billing.enums.TransferStatus;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * Output shape of a transfer in API v1.
 */
public record TransferResponse(
        long id,
        long fromWalletId,
        long toWalletId,
        long amount,
        String currency,
        TransferStatus status,
        Instant createdAt) {

    public static TransferResponse from(Transfer transfer) {
        return new TransferResponse(
                transfer.getId(),
                transfer.getFromWalletId(),
                transfer.getToWalletId(),
                transfer.getAmount(),
                transfer.getCurrency(),
                transfer.getStatus(),
                transfer.getCreatedAt().truncatedTo(ChronoUnit.SECONDS));
    }
}
