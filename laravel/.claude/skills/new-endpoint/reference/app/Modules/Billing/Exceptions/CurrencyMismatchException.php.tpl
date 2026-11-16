<?php

declare(strict_types=1);

namespace App\Modules\Billing\Exceptions;

use App\Core\Exceptions\BusinessRuleException;

final class CurrencyMismatchException extends BusinessRuleException
{
    public function __construct()
    {
        parent::__construct('Transfers are allowed only between wallets of the same currency.');
    }

    public function errorCode(): string
    {
        return 'currency_mismatch';
    }
}
