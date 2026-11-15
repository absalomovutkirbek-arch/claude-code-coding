<?php

declare(strict_types=1);

namespace App\Modules\Billing\Http\Actions\Transfer;

use App\Core\Http\ApiResponse;
use App\Modules\Billing\Http\Resources\TransferResource;
use App\Modules\Billing\Services\TransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class ViewTransferAction
{
    public function __construct(private readonly TransferService $service) {}

    public function __invoke(Request $request, int $id): JsonResponse
    {
        $transfer = $this->service->getForActor($id, (int) $request->user()->getAuthIdentifier());

        return ApiResponse::ok(TransferResource::make($transfer));
    }
}
