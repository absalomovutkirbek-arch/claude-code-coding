<?php

declare(strict_types=1);

namespace app\modules\billing\dto;

final class CreateTransferDto
{
    /**
     * @param int $amount Minor units.
     */
    public function __construct(
        public readonly int $actorId,
        public readonly int $fromWalletId,
        public readonly int $toWalletId,
        public readonly int $amount,
    ) {
    }
}
