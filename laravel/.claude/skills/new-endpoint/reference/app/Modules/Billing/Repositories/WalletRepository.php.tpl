<?php

declare(strict_types=1);

namespace App\Modules\Billing\Repositories;

use App\Modules\Billing\Models\Wallet;
use Illuminate\Support\Collection;

final class WalletRepository implements WalletRepositoryInterface
{
    public function lockByIds(array $ids): Collection
    {
        return Wallet::query()
            ->whereIn('id', $ids)
            ->orderBy('id')
            ->lockForUpdate()
            ->get()
            ->keyBy('id');
    }

    public function save(Wallet $wallet): void
    {
        $wallet->save();
    }
}
