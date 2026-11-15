<?php

declare(strict_types=1);

namespace app\modules\billing\repositories;

use app\core\data\Page;
use app\modules\billing\dto\TransferFilterDto;
use app\modules\billing\models\Transfer;
use RuntimeException;

final class TransferRepository implements TransferRepositoryInterface
{
    public function findById(int $id): ?Transfer
    {
        return Transfer::findOne($id);
    }

    public function save(Transfer $transfer): void
    {
        if (!$transfer->save(false)) {
            throw new RuntimeException('Failed to save transfer.');
        }
    }

    public function paginate(TransferFilterDto $filter): Page
    {
        $query = Transfer::find()
            ->where(['initiator_id' => $filter->initiatorId])
            ->andFilterWhere(['status' => $filter->status?->value]);

        $total = (int) $query->count();

        $items = $query
            ->orderBy(['id' => SORT_DESC])
            ->offset(($filter->page - 1) * $filter->perPage)
            ->limit($filter->perPage)
            ->all();

        return new Page($items, $total, $filter->page, $filter->perPage);
    }
}
