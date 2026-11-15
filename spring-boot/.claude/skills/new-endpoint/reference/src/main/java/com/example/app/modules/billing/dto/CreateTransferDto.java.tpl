package com.example.app.modules.billing.dto;

/**
 * @param amount minor units
 */
public record CreateTransferDto(long actorId, long fromWalletId, long toWalletId, long amount) {
}
