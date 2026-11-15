<?php

declare(strict_types=1);

namespace App\Core\Db;

use Illuminate\Database\DatabaseManager;

final class DbTransactionManager implements TransactionManagerInterface
{
    public function __construct(private readonly DatabaseManager $db) {}

    public function run(callable $callback): mixed
    {
        return $this->db->connection()->transaction(static fn () => $callback());
    }
}
