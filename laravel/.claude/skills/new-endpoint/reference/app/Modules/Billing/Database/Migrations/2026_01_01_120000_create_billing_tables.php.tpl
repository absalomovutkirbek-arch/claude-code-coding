<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('CREATE SCHEMA IF NOT EXISTS billing');

        Schema::create('billing.wallets', static function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('owner_id');
            $table->bigInteger('balance')->default(0)->comment('Minor units');
            $table->char('currency', 3);
            $table->timestampsTz();

            $table->unique(['owner_id', 'currency'], 'uq_wallets_owner_id_currency');
        });
        DB::statement('ALTER TABLE billing.wallets ADD CONSTRAINT ck_wallets_balance_non_negative CHECK (balance >= 0)');

        Schema::create('billing.transfers', static function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('initiator_id');
            $table->unsignedBigInteger('from_wallet_id');
            $table->unsignedBigInteger('to_wallet_id');
            $table->bigInteger('amount')->comment('Minor units');
            $table->char('currency', 3);
            $table->string('status', 32);
            $table->timestampsTz();

            $table->foreign('from_wallet_id', 'fk_transfers_from_wallet_id')
                ->references('id')->on('billing.wallets')->restrictOnDelete();
            $table->foreign('to_wallet_id', 'fk_transfers_to_wallet_id')
                ->references('id')->on('billing.wallets')->restrictOnDelete();
            $table->index('from_wallet_id', 'idx_transfers_from_wallet_id');
            $table->index('to_wallet_id', 'idx_transfers_to_wallet_id');
            $table->index(['initiator_id', 'status'], 'idx_transfers_initiator_id_status');
        });
        DB::statement('ALTER TABLE billing.transfers ADD CONSTRAINT ck_transfers_amount_positive CHECK (amount > 0)');
        DB::statement(
            "ALTER TABLE billing.transfers ADD CONSTRAINT ck_transfers_status CHECK (status IN ('completed', 'reversed'))"
        );
    }

    public function down(): void
    {
        Schema::dropIfExists('billing.transfers');
        Schema::dropIfExists('billing.wallets');
        DB::statement('DROP SCHEMA IF EXISTS billing');
    }
};
