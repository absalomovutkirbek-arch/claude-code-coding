<?php

declare(strict_types=1);

namespace app\core\events;

use yii\di\Container;

/**
 * Resolves listeners from the DI container and calls their handle() method.
 *
 * The event => listeners map lives in config/events.php.
 */
final class EventDispatcher implements EventDispatcherInterface
{
    /**
     * @param array<class-string, list<class-string>> $listeners
     */
    public function __construct(private readonly Container $container, private readonly array $listeners)
    {
    }

    public function dispatch(object $event): void
    {
        foreach ($this->listeners[$event::class] ?? [] as $listenerClass) {
            $this->container->get($listenerClass)->handle($event);
        }
    }
}
