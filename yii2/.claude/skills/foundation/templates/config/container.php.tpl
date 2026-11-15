<?php

declare(strict_types=1);

use app\core\db\DbTransactionManager;
use app\core\db\TransactionManagerInterface;
use app\core\events\EventDispatcher;
use app\core\events\EventDispatcherInterface;
use yii\di\Container;

/**
 * Interface => implementation bindings. One section per module.
 *
 * Loaded by web, console and test configs: 'container' => require __DIR__ . '/container.php'.
 */
return [
    'singletons' => [
        // Shared kernel
        // Never bind yii\db\Connection itself here: Yii builds the `db` component through
        // this container, so such a binding recurses.
        TransactionManagerInterface::class => static fn (): TransactionManagerInterface =>
            new DbTransactionManager(Yii::$app->db),
        EventDispatcherInterface::class => static fn (Container $container): EventDispatcherInterface =>
            new EventDispatcher($container, require __DIR__ . '/events.php'),

        // <module>
        // OrderRepositoryInterface::class => OrderRepository::class,
    ],
];
