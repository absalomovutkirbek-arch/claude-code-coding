<?php

declare(strict_types=1);

namespace app\core\db;

use yii\behaviors\TimestampBehavior;

/**
 * Fills created_at / updated_at with a UTC timestamp string.
 *
 * A plain string (not a DB expression) keeps the attribute readable right after save().
 */
final class UtcTimestampBehavior extends TimestampBehavior
{
    protected function getValue($event): string
    {
        return gmdate('Y-m-d\TH:i:s\Z');
    }
}
