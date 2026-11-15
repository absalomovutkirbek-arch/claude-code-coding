<?php

declare(strict_types=1);

namespace app\core\db;

use yii\db\Connection;

final class DbTransactionManager implements TransactionManagerInterface
{
    public function __construct(private readonly Connection $db)
    {
    }

    public function run(callable $callback): mixed
    {
        return $this->db->transaction(static fn () => $callback());
    }
}
