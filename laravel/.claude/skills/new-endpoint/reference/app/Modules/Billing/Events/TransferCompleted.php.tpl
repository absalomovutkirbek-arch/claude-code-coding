<?php

declare(strict_types=1);

namespace App\Modules\Billing\Events;

use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;

/**
 * Dispatched after the transfer transaction has committed.
 */
final readonly class TransferCompleted implements ShouldDispatchAfterCommit
{
    public function __construct(public int $transferId) {}
}
