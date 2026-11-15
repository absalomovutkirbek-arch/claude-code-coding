<?php

declare(strict_types=1);

namespace app\modules\billing\migrations;

use yii\db\Migration;

final class M260101120000CreateBillingTables extends Migration
{
    public function safeUp(): void
    {
        $this->execute('CREATE SCHEMA IF NOT EXISTS billing');

        $this->createTable('billing.wallet', [
            'id' => $this->bigPrimaryKey(),
            'owner_id' => $this->bigInteger()->notNull(),
            'balance' => $this->bigInteger()->notNull()->defaultValue(0)->comment('Minor units'),
            'currency' => $this->char(3)->notNull(),
            'created_at' => 'timestamptz NOT NULL DEFAULT NOW()',
            'updated_at' => 'timestamptz NOT NULL DEFAULT NOW()',
        ]);
        $this->execute('ALTER TABLE billing.wallet ADD CONSTRAINT ck_wallet_balance_non_negative CHECK (balance >= 0)');
        $this->createIndex('uq_wallet_owner_id_currency', 'billing.wallet', ['owner_id', 'currency'], true);

        $this->createTable('billing.transfer', [
            'id' => $this->bigPrimaryKey(),
            'initiator_id' => $this->bigInteger()->notNull(),
            'from_wallet_id' => $this->bigInteger()->notNull(),
            'to_wallet_id' => $this->bigInteger()->notNull(),
            'amount' => $this->bigInteger()->notNull()->comment('Minor units'),
            'currency' => $this->char(3)->notNull(),
            'status' => $this->string(32)->notNull(),
            'created_at' => 'timestamptz NOT NULL DEFAULT NOW()',
            'updated_at' => 'timestamptz NOT NULL DEFAULT NOW()',
        ]);
        $this->execute('ALTER TABLE billing.transfer ADD CONSTRAINT ck_transfer_amount_positive CHECK (amount > 0)');
        $this->execute(
            "ALTER TABLE billing.transfer ADD CONSTRAINT ck_transfer_status CHECK (status IN ('completed', 'reversed'))"
        );
        $this->addForeignKey(
            'fk_transfer_from_wallet_id',
            'billing.transfer',
            'from_wallet_id',
            'billing.wallet',
            'id',
            'RESTRICT',
        );
        $this->addForeignKey(
            'fk_transfer_to_wallet_id',
            'billing.transfer',
            'to_wallet_id',
            'billing.wallet',
            'id',
            'RESTRICT',
        );
        $this->createIndex('idx_transfer_from_wallet_id', 'billing.transfer', 'from_wallet_id');
        $this->createIndex('idx_transfer_to_wallet_id', 'billing.transfer', 'to_wallet_id');
        $this->createIndex('idx_transfer_initiator_id_status', 'billing.transfer', ['initiator_id', 'status']);
    }

    public function safeDown(): void
    {
        $this->dropTable('billing.transfer');
        $this->dropTable('billing.wallet');
        $this->execute('DROP SCHEMA billing');
    }
}
