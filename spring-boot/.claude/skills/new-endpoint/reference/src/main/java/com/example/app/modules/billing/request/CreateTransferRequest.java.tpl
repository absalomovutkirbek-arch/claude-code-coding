package com.example.app.modules.billing.request;

import com.example.app.modules.billing.dto.CreateTransferDto;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/**
 * Input format of POST /api/v1/billing/transfers.
 */
public record CreateTransferRequest(
        @NotNull @Positive Long fromWalletId,
        @NotNull @Positive Long toWalletId,
        @NotNull @Positive Long amount) {

    /** Cross-field check. Named after the field so that the error is reported under {@code to_wallet_id}. */
    @AssertTrue(message = "Source and destination wallets must be different.")
    public boolean isToWalletId() {
        return fromWalletId == null || !fromWalletId.equals(toWalletId);
    }

    public CreateTransferDto toDto(long actorId) {
        return new CreateTransferDto(actorId, fromWalletId, toWalletId, amount);
    }
}
