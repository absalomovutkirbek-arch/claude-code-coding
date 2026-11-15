<?php

declare(strict_types=1);

namespace App\Core\Pipeline;

use Closure;

/**
 * One step of a use case run through Illuminate\Pipeline\Pipeline (Chain of Responsibility).
 *
 * A handler does its single step on the shared context and passes it on: `return $next($context);`.
 * It stops the chain by throwing a domain exception.
 */
interface HandlerInterface
{
    /**
     * @param  Closure(object): object  $next
     */
    public function handle(object $context, Closure $next): object;
}
