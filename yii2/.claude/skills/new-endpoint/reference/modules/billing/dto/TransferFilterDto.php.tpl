<?php

declare(strict_types=1);

namespace app\modules\billing\dto;

use app\modules\billing\enums\TransferStatus;

final class TransferFilterDto
{
    public function __construct(
        public readonly int $initiatorId,
        public readonly ?TransferStatus $status = null,
        public readonly int $page = 1,
        public readonly int $perPage = 20,
    ) {
    }
}
