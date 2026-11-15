<?php

declare(strict_types=1);

namespace app\modules\billing\events;

/**
 * Dispatched after the transfer transaction has committed.
 */
final class TransferCompleted
{
    public function __construct(public readonly int $transferId)
    {
    }
}
