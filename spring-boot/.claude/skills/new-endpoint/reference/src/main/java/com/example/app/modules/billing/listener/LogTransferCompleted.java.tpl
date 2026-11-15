package com.example.app.modules.billing.listener;

import com.example.app.modules.billing.event.TransferCompleted;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class LogTransferCompleted {

    private static final Logger log = LoggerFactory.getLogger(LogTransferCompleted.class);

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handle(TransferCompleted event) {
        log.info("Transfer completed: transfer_id={}", event.transferId());
    }
}
