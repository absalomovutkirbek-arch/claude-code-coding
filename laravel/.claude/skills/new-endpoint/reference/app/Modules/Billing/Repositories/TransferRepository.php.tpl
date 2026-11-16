<?php

declare(strict_types=1);

namespace App\Modules\Billing\Repositories;

use App\Modules\Billing\Dto\TransferFilterDto;
use App\Modules\Billing\Models\Transfer;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

final class TransferRepository implements TransferRepositoryInterface
{
    public function findById(int $id): ?Transfer
    {
        return Transfer::query()->find($id);
    }

    public function save(Transfer $transfer): void
    {
        $transfer->save();
    }

    public function paginate(TransferFilterDto $filter): LengthAwarePaginator
    {
        return Transfer::query()
            ->where('initiator_id', $filter->initiatorId)
            ->when($filter->status !== null, static fn (Builder $query) => $query->where('status', $filter->status))
            ->orderByDesc('id')
            ->paginate(perPage: $filter->perPage, page: $filter->page);
    }
}
