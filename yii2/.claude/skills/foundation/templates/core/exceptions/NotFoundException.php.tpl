<?php

declare(strict_types=1);

namespace app\core\exceptions;

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
