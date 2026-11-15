<?php

declare(strict_types=1);

namespace app\modules\billing\controllers;

use app\core\http\ApiController;
use app\modules\billing\actions\transfer\CreateTransferAction;
use app\modules\billing\actions\transfer\ListTransfersAction;
use app\modules\billing\actions\transfer\ViewTransferAction;

final class TransferController extends ApiController
{
    public function actions(): array
    {
        return [
            'create' => CreateTransferAction::class,
            'index' => ListTransfersAction::class,
            'view' => ViewTransferAction::class,
        ];
    }

    protected function verbs(): array
    {
        return [
            'create' => ['POST'],
            'index' => ['GET'],
            'view' => ['GET'],
        ];
    }
}
