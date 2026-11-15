<?php

declare(strict_types=1);

namespace app\core\exceptions;

/**
 * A business rule rejected the operation. HTTP 422.
 *
 * Module exceptions extend this class and override errorCode() with a specific code.
 */
class BusinessRuleException extends DomainException
{
    public function errorCode(): string
    {
        return 'business_rule_violation';
    }
}
