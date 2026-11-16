<?php

declare(strict_types=1);

use App\Modules\Billing\Http\Actions\Transfer\CreateTransferAction;
use App\Modules\Billing\Http\Actions\Transfer\ListTransfersAction;
use App\Modules\Billing\Http\Actions\Transfer\ViewTransferAction;
use Illuminate\Support\Facades\Route;

// Prefix api/v1/billing and middleware are applied in BillingServiceProvider.
Route::post('transfers', CreateTransferAction::class);
Route::get('transfers', ListTransfersAction::class);
Route::get('transfers/{id}', ViewTransferAction::class)->whereNumber('id');
