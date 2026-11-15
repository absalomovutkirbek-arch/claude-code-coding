<?php

declare(strict_types=1);

namespace App\Modules\Billing\Repositories;

use App\Modules\Billing\Models\Wallet;
use Illuminate\Support\Collection;

interface WalletRepositoryInterface
{
    /**
     * Loads the wallets with a row lock (SELECT ... FOR UPDATE), in ID order to avoid deadlocks.
     * Must be called inside a transaction.
     *
     * @param  list<int>  $ids
     * @return Collection<int, Wallet> Keyed by wallet ID. Missing IDs are absent.
     */
    public function lockByIds(array $ids): Collection;

    public function save(Wallet $wallet): void;
}
