<?php

declare(strict_types=1);

namespace App\Modules\Billing\Providers;

use App\Modules\Billing\Events\TransferCompleted;
use App\Modules\Billing\Listeners\LogTransferCompleted;
use App\Modules\Billing\Repositories\TransferRepository;
use App\Modules\Billing\Repositories\TransferRepositoryInterface;
use App\Modules\Billing\Repositories\WalletRepository;
use App\Modules\Billing\Repositories\WalletRepositoryInterface;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

/**
 * Wires the billing module: bindings, routes, migrations, listeners.
 */
final class BillingServiceProvider extends ServiceProvider
{
    /** @var array<class-string, class-string> */
    public array $bindings = [
        WalletRepositoryInterface::class => WalletRepository::class,
        TransferRepositoryInterface::class => TransferRepository::class,
    ];

    public function boot(): void
    {
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');

        Route::middleware(['api', 'auth:sanctum'])
            ->prefix('api/v1/billing')
            ->group(__DIR__.'/../routes/api.php');

        Event::listen(TransferCompleted::class, LogTransferCompleted::class);
    }
}
