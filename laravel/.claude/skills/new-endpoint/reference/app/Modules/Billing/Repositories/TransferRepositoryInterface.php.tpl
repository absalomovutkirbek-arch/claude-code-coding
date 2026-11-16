<?php

declare(strict_types=1);

namespace App\Modules\Billing\Repositories;

use App\Modules\Billing\Dto\TransferFilterDto;
use App\Modules\Billing\Models\Transfer;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface TransferRepositoryInterface
{
    public function findById(int $id): ?Transfer;

    public function save(Transfer $transfer): void;

    /**
     * @return LengthAwarePaginator<int, Transfer> Newest first.
     */
    public function paginate(TransferFilterDto $filter): LengthAwarePaginator;
}
