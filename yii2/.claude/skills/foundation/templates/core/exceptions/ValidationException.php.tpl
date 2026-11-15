<?php

declare(strict_types=1);

namespace app\core\exceptions;

/**
 * Input validation failed. HTTP 422.
 */
final class ValidationException extends DomainException
{
    /**
     * @param array<string, string[]> $errors Field name => list of messages.
     */
    public function __construct(array $errors, string $message = 'The given data is invalid.')
    {
        parent::__construct($message, $errors);
    }

    public function errorCode(): string
    {
        return 'validation_failed';
    }
}
