<?php

declare(strict_types=1);

namespace App\Modules\Billing\Listeners;

use App\Modules\Billing\Events\TransferCompleted;
use Psr\Log\LoggerInterface;

final class LogTransferCompleted
{
    public function __construct(private readonly LoggerInterface $logger) {}

    public function handle(TransferCompleted $event): void
    {
        $this->logger->info('Transfer completed', ['transfer_id' => $event->transferId]);
    }
}
