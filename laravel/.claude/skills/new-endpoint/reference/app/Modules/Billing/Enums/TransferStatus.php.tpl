<?php

declare(strict_types=1);

namespace App\Modules\Billing\Enums;

enum TransferStatus: string
{
    case Completed = 'completed';
    case Reversed = 'reversed';
}
