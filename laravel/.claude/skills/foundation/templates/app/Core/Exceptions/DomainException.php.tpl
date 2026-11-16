<?php

declare(strict_types=1);

namespace App\Core\Exceptions;

use RuntimeException;
use Throwable;

/**
 * Base class for every expected, business-level failure.
 *
 * Domain exceptions know nothing about HTTP. ApiExceptionRenderer maps them to status codes.
 */
abstract class DomainException extends RuntimeException
{
    /**
     * @param  string  $message  Safe to show to the API consumer.
     * @param  array<string, mixed>  $details  Structured context returned as `error.details`.
     */
    public function __construct(string $message, private readonly array $details = [], ?Throwable $previous = null)
    {
        parent::__construct($message, 0, $previous);
    }

    /**
     * Stable machine-readable code returned as `error.code`. Override in module exceptions.
     */
    abstract public function errorCode(): string;

    /**
     * @return array<string, mixed>
     */
    public function details(): array
    {
        return $this->details;
    }
}
