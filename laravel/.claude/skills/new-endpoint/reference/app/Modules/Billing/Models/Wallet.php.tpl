<?php

declare(strict_types=1);

namespace App\Modules\Billing\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * Table mapping only. Queries live in WalletRepository, rules in TransferService.
 *
 * @property int $id
 * @property int $owner_id
 * @property int $balance Minor units.
 * @property string $currency
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
final class Wallet extends Model
{
    protected $table = 'billing.wallets';

    protected $guarded = ['id'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'owner_id' => 'integer',
            'balance' => 'integer',
        ];
    }
}
