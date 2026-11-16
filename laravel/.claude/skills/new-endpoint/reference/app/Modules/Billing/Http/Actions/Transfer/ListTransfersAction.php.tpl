<?php

declare(strict_types=1);

namespace App\Modules\Billing\Http\Actions\Transfer;

use App\Core\Http\ApiResponse;
use App\Modules\Billing\Http\Requests\ListTransfersRequest;
use App\Modules\Billing\Http\Resources\TransferResource;
use App\Modules\Billing\Services\TransferService;
use Illuminate\Http\JsonResponse;

final class ListTransfersAction
{
    public function __construct(private readonly TransferService $service) {}

    public function __invoke(ListTransfersRequest $request): JsonResponse
    {
        $page = $this->service->list($request->toDto());

        return ApiResponse::paginated($page, TransferResource::class);
    }
}
