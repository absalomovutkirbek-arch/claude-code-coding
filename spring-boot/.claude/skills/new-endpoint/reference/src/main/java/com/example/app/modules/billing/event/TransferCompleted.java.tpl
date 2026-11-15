package com.example.app.modules.billing.event;

/**
 * Published inside the transfer transaction and delivered to listeners after it commits.
 */
public record TransferCompleted(long transferId) {
}
