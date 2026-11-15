<?php

declare(strict_types=1);

namespace app\modules\billing\forms;

use app\modules\billing\dto\CreateTransferDto;
use yii\base\Model;

/**
 * Input format of POST /v1/billing/transfers.
 *
 * Properties stay untyped: they hold raw input until rules() has checked it.
 */
final class CreateTransferForm extends Model
{
    /** @var int|string|null */
    public $from_wallet_id;
    /** @var int|string|null */
    public $to_wallet_id;
    /** @var int|string|null Amount in minor units. */
    public $amount;

    public function rules(): array
    {
        return [
            [['from_wallet_id', 'to_wallet_id', 'amount'], 'required'],
            [['from_wallet_id', 'to_wallet_id', 'amount'], 'integer', 'min' => 1],
            [
                'to_wallet_id',
                'compare',
                'compareAttribute' => 'from_wallet_id',
                'operator' => '!=',
                'type' => 'number',
                'message' => 'Source and destination wallets must be different.',
            ],
        ];
    }

    public function toDto(int $actorId): CreateTransferDto
    {
        return new CreateTransferDto(
            actorId: $actorId,
            fromWalletId: (int) $this->from_wallet_id,
            toWalletId: (int) $this->to_wallet_id,
            amount: (int) $this->amount,
        );
    }
}
