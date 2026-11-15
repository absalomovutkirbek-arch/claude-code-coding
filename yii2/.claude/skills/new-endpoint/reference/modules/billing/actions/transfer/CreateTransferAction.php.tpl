<?php

declare(strict_types=1);

namespace app\modules\billing\actions\transfer;

use app\core\http\ApiAction;
use app\modules\billing\forms\CreateTransferForm;
use app\modules\billing\resources\TransferResource;
use app\modules\billing\services\TransferService;

final class CreateTransferAction extends ApiAction
{
    public function __construct($id, $controller, private readonly TransferService $service, array $config = [])
    {
        parent::__construct($id, $controller, $config);
    }

    public function run(): array
    {
        $form = $this->validateBody(new CreateTransferForm());

        $transfer = $this->service->create($form->toDto($this->actorId()));

        return $this->created(TransferResource::make($transfer));
    }
}
