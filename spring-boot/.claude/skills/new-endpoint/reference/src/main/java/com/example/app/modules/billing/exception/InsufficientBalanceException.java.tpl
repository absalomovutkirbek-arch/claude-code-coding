package com.example.app.modules.billing.exception;

import com.example.app.core.exception.BusinessRuleException;
import java.util.Map;

public class InsufficientBalanceException extends BusinessRuleException {

    public InsufficientBalanceException(long walletId) {
        super("The wallet balance is not sufficient for this transfer.", Map.of("wallet_id", walletId));
    }

    @Override
    public String errorCode() {
        return "insufficient_balance";
    }
}
