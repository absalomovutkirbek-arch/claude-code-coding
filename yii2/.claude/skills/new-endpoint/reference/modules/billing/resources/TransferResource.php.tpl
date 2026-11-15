<?php

declare(strict_types=1);

namespace app\modules\billing\resources;

use app\core\support\Iso8601;
use app\modules\billing\models\Transfer;

/**
 * Output shape of a transfer in API v1.
 */
final class TransferResource
{
    /**
     * @return array<string, mixed>
     */
    public static function make(Transfer $transfer): array
    {
        return [
            'id' => $transfer->id,
            'from_wallet_id' => $transfer->from_wallet_id,
            'to_wallet_id' => $transfer->to_wallet_id,
            'amount' => $transfer->amount,
            'currency' => $transfer->currency,
            'status' => $transfer->status,
            'created_at' => Iso8601::fromDb($transfer->created_at),
        ];
    }

    /**
     * @param Transfer[] $transfers
     * @return list<array<string, mixed>>
     */
    public static function collection(array $transfers): array
    {
        return array_map(self::make(...), array_values($transfers));
    }
}
