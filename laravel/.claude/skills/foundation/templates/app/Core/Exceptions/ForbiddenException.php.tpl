<?php

declare(strict_types=1);

namespace App\Core\Exceptions;

/**
 * The caller is authenticated but not allowed to perform the operation. HTTP 403.
 */
class ForbiddenException extends DomainException
{
    public function errorCode(): string
    {
        return 'forbidden';
    }
}
