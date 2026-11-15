<?php

declare(strict_types=1);

namespace App\Modules\Billing\Dto;

use App\Modules\Billing\Enums\TransferStatus;

final readonly class TransferFilterDto
{
    public function __construct(
        public int $initiatorId,
        public ?TransferStatus $status = null,
        public int $page = 1,
        public int $perPage = 20,
    ) {}
}
