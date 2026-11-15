<?php

declare(strict_types=1);

namespace App\Modules\Billing\Http\Requests;

use App\Modules\Billing\Dto\TransferFilterDto;
use App\Modules\Billing\Enums\TransferStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Query parameters of GET /api/v1/billing/transfers.
 */
final class ListTransfersRequest extends FormRequest
{
    /**
     * @return array<string, list<mixed>>
     */
    public function rules(): array
    {
        return [
            'status' => ['sometimes', Rule::enum(TransferStatus::class)],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): TransferFilterDto
    {
        return new TransferFilterDto(
            initiatorId: (int) $this->user()->getAuthIdentifier(),
            status: $this->enum('status', TransferStatus::class),
            page: $this->integer('page', 1),
            perPage: $this->integer('per_page', 20),
        );
    }
}
