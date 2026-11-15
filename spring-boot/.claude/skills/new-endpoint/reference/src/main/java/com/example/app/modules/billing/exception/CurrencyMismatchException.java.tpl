package com.example.app.modules.billing.exception;

import com.example.app.core.exception.BusinessRuleException;

public class CurrencyMismatchException extends BusinessRuleException {

    public CurrencyMismatchException() {
        super("Transfers are possible only between wallets of the same currency.");
    }

    @Override
    public String errorCode() {
        return "currency_mismatch";
    }
}
