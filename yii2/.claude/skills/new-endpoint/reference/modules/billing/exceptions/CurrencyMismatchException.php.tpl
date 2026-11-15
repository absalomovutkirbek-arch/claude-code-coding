<?php

declare(strict_types=1);

namespace app\modules\billing\exceptions;

use app\core\exceptions\BusinessRuleException;

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
