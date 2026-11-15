<?php

declare(strict_types=1);

namespace app\modules\billing\models;

use app\core\db\UtcTimestampBehavior;
use yii\db\ActiveRecord;

/**
 * Table mapping only. Queries live in WalletRepository, rules in TransferService.
 *
 * @property int $id
 * @property int $owner_id
 * @property int $balance Minor units.
 * @property string $currency
 * @property string $created_at
 * @property string $updated_at
 */
final class Wallet extends ActiveRecord
{
    public static function tableName(): string
    {
        return 'billing.wallet';
    }

    public function behaviors(): array
    {
        return [UtcTimestampBehavior::class];
    }
}
