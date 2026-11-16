<?php

declare(strict_types=1);

namespace App\Modules\Billing\Http\Actions\Transfer;

use App\Core\Http\ApiResponse;
use App\Modules\Billing\Http\Requests\CreateTransferRequest;
use App\Modules\Billing\Http\Resources\TransferResource;
use App\Modules\Billing\Services\TransferService;
use Illuminate\Http\JsonResponse;

final class CreateTransferAction
{
    public function __construct(private readonly TransferService $service) {}

    public function __invoke(CreateTransferRequest $request): JsonResponse
    {
        $transfer = $this->service->create($request->toDto());

        return ApiResponse::created(TransferResource::make($transfer));
    }
}
