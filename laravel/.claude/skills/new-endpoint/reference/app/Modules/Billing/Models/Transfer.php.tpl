<?php

declare(strict_types=1);

namespace App\Modules\Billing\Models;

use App\Modules\Billing\Enums\TransferStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $initiator_id
 * @property int $from_wallet_id
 * @property int $to_wallet_id
 * @property int $amount Minor units.
 * @property string $currency
 * @property TransferStatus $status
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
final class Transfer extends Model
{
    protected $table = 'billing.transfers';

    protected $guarded = ['id'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'initiator_id' => 'integer',
            'from_wallet_id' => 'integer',
            'to_wallet_id' => 'integer',
            'amount' => 'integer',
            'status' => TransferStatus::class,
        ];
    }

    public static function completed(int $initiatorId, Wallet $from, Wallet $to, int $amount): self
    {
        $transfer = new self;
        $transfer->initiator_id = $initiatorId;
        $transfer->from_wallet_id = $from->id;
        $transfer->to_wallet_id = $to->id;
        $transfer->amount = $amount;
        $transfer->currency = $from->currency;
        $transfer->status = TransferStatus::Completed;

        return $transfer;
    }
}
