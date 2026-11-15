<?php

declare(strict_types=1);

namespace app\modules\billing\models;

use app\modules\billing\enums\TransferStatus;
use app\core\db\UtcTimestampBehavior;
use yii\db\ActiveRecord;

/**
 * @property int $id
 * @property int $initiator_id
 * @property int $from_wallet_id
 * @property int $to_wallet_id
 * @property int $amount Minor units.
 * @property string $currency
 * @property string $status
 * @property string $created_at
 * @property string $updated_at
 */
final class Transfer extends ActiveRecord
{
    public static function tableName(): string
    {
        return 'billing.transfer';
    }

    public function behaviors(): array
    {
        return [UtcTimestampBehavior::class];
    }

    public static function completed(int $initiatorId, Wallet $from, Wallet $to, int $amount): self
    {
        $transfer = new self();
        $transfer->initiator_id = $initiatorId;
        $transfer->from_wallet_id = $from->id;
        $transfer->to_wallet_id = $to->id;
        $transfer->amount = $amount;
        $transfer->currency = $from->currency;
        $transfer->status = TransferStatus::Completed->value;

        return $transfer;
    }

    public function statusEnum(): TransferStatus
    {
        return TransferStatus::from($this->status);
    }
}
