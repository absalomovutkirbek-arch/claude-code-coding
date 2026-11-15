<?php

declare(strict_types=1);

namespace App\Core\Exceptions;

/**
 * The resource does not exist or is not visible to the caller. HTTP 404.
 */
class NotFoundException extends DomainException
{
    public function errorCode(): string
    {
        return 'not_found';
    }
}
