<?php

declare(strict_types=1);

namespace app\modules\billing\listeners;

use app\modules\billing\events\TransferCompleted;
use Yii;

final class LogTransferCompletedListener
{
    public function handle(TransferCompleted $event): void
    {
        Yii::info(['message' => 'Transfer completed', 'transfer_id' => $event->transferId], 'billing');
    }
}
