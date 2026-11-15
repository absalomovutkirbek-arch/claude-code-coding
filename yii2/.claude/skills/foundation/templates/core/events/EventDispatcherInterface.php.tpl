<?php

declare(strict_types=1);

namespace app\core\events;

interface EventDispatcherInterface
{
    /**
     * Delivers the event to every listener registered for its class.
     *
     * Call it after the transaction has committed.
     */
    public function dispatch(object $event): void;
}
