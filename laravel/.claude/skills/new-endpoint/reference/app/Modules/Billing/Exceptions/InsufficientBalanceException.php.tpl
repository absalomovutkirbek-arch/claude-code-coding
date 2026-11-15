<?php

declare(strict_types=1);

namespace App\Modules\Billing\Exceptions;

use App\Core\Exceptions\BusinessRuleException;

final class InsufficientBalanceException extends BusinessRuleException
{
    public function __construct(int $walletId)
    {
        parent::__construct('The wallet balance is not sufficient for this transfer.', ['wallet_id' => $walletId]);
    }

    public function errorCode(): string
    {
        return 'insufficient_balance';
    }
}
