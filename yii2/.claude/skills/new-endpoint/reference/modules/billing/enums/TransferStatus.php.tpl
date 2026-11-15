<?php

declare(strict_types=1);

namespace app\modules\billing\enums;

enum TransferStatus: string
{
    case Completed = 'completed';
    case Reversed = 'reversed';
}
