<?php

declare(strict_types=1);

namespace app\core\support;

use DateTimeImmutable;
use DateTimeZone;

final class Iso8601
{
    /**
     * Converts a database timestamp to the API format: 2026-01-31T09:30:00Z.
     */
    public static function fromDb(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        return (new DateTimeImmutable($value, new DateTimeZone('UTC')))
            ->setTimezone(new DateTimeZone('UTC'))
            ->format('Y-m-d\TH:i:s\Z');
    }
}
