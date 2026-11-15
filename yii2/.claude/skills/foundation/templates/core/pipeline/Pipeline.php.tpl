<?php

declare(strict_types=1);

namespace app\core\pipeline;

/**
 * Runs handlers in the declared order over one context object.
 */
final class Pipeline
{
    /** @var HandlerInterface[] */
    private readonly array $handlers;

    public function __construct(HandlerInterface ...$handlers)
    {
        $this->handlers = $handlers;
    }

    /**
     * @template T of object
     * @param T $context
     * @return T
     */
    public function process(object $context): object
    {
        $chain = array_reduce(
            array_reverse($this->handlers),
            static fn (callable $next, HandlerInterface $handler): callable =>
                static fn (object $context): object => $handler->handle($context, $next),
            static fn (object $context): object => $context,
        );

        return $chain($context);
    }
}
