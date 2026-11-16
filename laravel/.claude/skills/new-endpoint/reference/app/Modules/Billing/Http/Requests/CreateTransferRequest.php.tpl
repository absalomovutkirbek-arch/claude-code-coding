<?php

declare(strict_types=1);

namespace App\Modules\Billing\Http\Requests;

use App\Modules\Billing\Dto\CreateTransferDto;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Input format of POST /api/v1/billing/transfers.
 */
final class CreateTransferRequest extends FormRequest
{
    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'from_wallet_id' => ['required', 'integer', 'min:1'],
            'to_wallet_id' => ['required', 'integer', 'min:1', 'different:from_wallet_id'],
            'amount' => ['required', 'integer', 'min:1'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'to_wallet_id.different' => 'Source and destination wallets must be different.',
        ];
    }

    public function toDto(): CreateTransferDto
    {
        return new CreateTransferDto(
            actorId: (int) $this->user()->getAuthIdentifier(),
            fromWalletId: $this->integer('from_wallet_id'),
            toWalletId: $this->integer('to_wallet_id'),
            amount: $this->integer('amount'),
        );
    }
}
