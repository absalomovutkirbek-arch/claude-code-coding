<?php

declare(strict_types=1);

namespace App\Core\Db;

interface TransactionManagerInterface
{
    /**
     * Runs the callback inside a database transaction.
     *
     * Commits when the callback returns, rolls back and rethrows when it throws.
     * Nested calls join the outer transaction through savepoints.
     *
     * @template T
     *
     * @param  callable(): T  $callback
     * @return T
     */
    public function run(callable $callback): mixed;
}
