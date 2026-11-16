<?php

declare(strict_types=1);

namespace App\Modules\Billing\Dto;

final readonly class CreateTransferDto
{
    /**
     * @param  int  $amount  Minor units.
     */
    public function __construct(
        public int $actorId,
        public int $fromWalletId,
        public int $toWalletId,
        public int $amount,
    ) {}
}
