<?php

declare(strict_types=1);

/**
 * Event class => listener classes. Listeners are resolved from the DI container
 * and must have a `handle(<Event> $event): void` method.
 */
return [
    // OrderPlaced::class => [SendOrderConfirmationListener::class],
];
