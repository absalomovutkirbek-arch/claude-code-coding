<?php

declare(strict_types=1);

namespace app\modules\billing\repositories;

use app\modules\billing\models\Wallet;
use RuntimeException;

final class WalletRepository implements WalletRepositoryInterface
{
    public function lockByIds(array $ids): array
    {
        $command = Wallet::find()
            ->where(['id' => $ids])
            ->orderBy(['id' => SORT_ASC])
            ->createCommand();

        return Wallet::findBySql($command->getSql() . ' FOR UPDATE', $command->params)
            ->indexBy('id')
            ->all();
    }

    public function save(Wallet $wallet): void
    {
        if (!$wallet->save(false)) {
            throw new RuntimeException('Failed to save wallet.');
        }
    }
}
