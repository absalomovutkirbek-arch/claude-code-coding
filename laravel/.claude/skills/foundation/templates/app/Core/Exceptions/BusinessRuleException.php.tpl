<?php

declare(strict_types=1);

namespace App\Core\Exceptions;

/**
 * A business rule rejected the operation. HTTP 422. Module exceptions extend this class and override errorCode().
 */
class BusinessRuleException extends DomainException
{
    public function errorCode(): string
    {
        return 'business_rule_violation';
    }
}
