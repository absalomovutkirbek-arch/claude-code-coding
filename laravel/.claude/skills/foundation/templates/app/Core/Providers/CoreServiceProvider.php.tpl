<?php

declare(strict_types=1);

namespace App\Core\Providers;

use App\Core\Db\DbTransactionManager;
use App\Core\Db\TransactionManagerInterface;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

final class CoreServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(TransactionManagerInterface::class, DbTransactionManager::class);
    }

    public function boot(): void
    {
        // Outside production: lazy loading (N+1), unknown attributes and silently dropped fills throw.
        Model::shouldBeStrict(! $this->app->isProduction());
    }
}
