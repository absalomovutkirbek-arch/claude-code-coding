<?php

declare(strict_types=1);

namespace app\core\pipeline;

/**
 * One step of a pipeline (Chain of Responsibility).
 *
 * A handler does its work on the context and passes it on with `return $next($context);`.
 * It stops the chain by throwing a domain exception or by returning without calling $next.
 */
interface HandlerInterface
{
    /**
     * @param callable(object): object $next
     */
    public function handle(object $context, callable $next): object;
}
