<?php

declare(strict_types=1);

namespace app\modules\billing\actions\transfer;

use app\core\http\ApiAction;
use app\modules\billing\forms\ListTransfersForm;
use app\modules\billing\resources\TransferResource;
use app\modules\billing\services\TransferService;

final class ListTransfersAction extends ApiAction
{
    public function __construct($id, $controller, private readonly TransferService $service, array $config = [])
    {
        parent::__construct($id, $controller, $config);
    }

    public function run(): array
    {
        $form = $this->validateQuery(new ListTransfersForm());

        $page = $this->service->list($form->toDto($this->actorId()));

        return $this->paginated($page, TransferResource::collection(...));
    }
}
