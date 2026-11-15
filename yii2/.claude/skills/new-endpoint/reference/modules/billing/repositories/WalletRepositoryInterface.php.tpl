<?php

declare(strict_types=1);

namespace app\modules\billing\repositories;

use app\modules\billing\models\Wallet;

interface WalletRepositoryInterface
{
    /**
     * Loads the wallets with a row lock (SELECT ... FOR UPDATE), in ID order to avoid deadlocks.
     * Must be called inside a transaction.
     *
     * @param int[] $ids
     * @return array<int, Wallet> Indexed by wallet ID. Missing IDs are absent.
     */
    public function lockByIds(array $ids): array;

    public function save(Wallet $wallet): void;
}
