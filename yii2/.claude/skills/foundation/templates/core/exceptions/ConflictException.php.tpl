<?php

declare(strict_types=1);

namespace app\core\exceptions;

/**
 * Duplicate or concurrent modification. HTTP 409.
 */
class ConflictException extends DomainException
{
    public function errorCode(): string
    {
        return 'conflict';
    }
}
