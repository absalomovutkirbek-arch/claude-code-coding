<?php

declare(strict_types=1);

namespace app\modules\billing\repositories;

use app\core\data\Page;
use app\modules\billing\dto\TransferFilterDto;
use app\modules\billing\models\Transfer;

interface TransferRepositoryInterface
{
    public function findById(int $id): ?Transfer;

    public function save(Transfer $transfer): void;

    /**
     * @return Page<Transfer> Newest first.
     */
    public function paginate(TransferFilterDto $filter): Page;
}
