<?php

declare(strict_types=1);

namespace app\modules\billing\actions\transfer;

use app\core\http\ApiAction;
use app\modules\billing\resources\TransferResource;
use app\modules\billing\services\TransferService;

final class ViewTransferAction extends ApiAction
{
    public function __construct($id, $controller, private readonly TransferService $service, array $config = [])
    {
        parent::__construct($id, $controller, $config);
    }

    public function run(int $id): array
    {
        $transfer = $this->service->getForActor($id, $this->actorId());

        return $this->ok(TransferResource::make($transfer));
    }
}
