<?php

declare(strict_types=1);

namespace Tests\Feature\Modules\Billing;

use App\Models\User;
use App\Modules\Billing\Events\TransferCompleted;
use App\Modules\Billing\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

/**
 * Endpoint test: real routing, validation, service, repositories and PostgreSQL.
 */
final class TransferApiTest extends TestCase
{
    use RefreshDatabase;

    private const URL = '/api/v1/billing/transfers';

    public function test_create_transfer_moves_money_and_returns201(): void
    {
        Event::fake([TransferCompleted::class]);
        $user = User::factory()->create();
        $from = $this->wallet($user->id, 1_000);
        $to = $this->wallet(User::factory()->create()->id, 0);

        $response = $this->actingAs($user, 'sanctum')->postJson(self::URL, [
            'from_wallet_id' => $from->id,
            'to_wallet_id' => $to->id,
            'amount' => 300,
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.amount', 300)
            ->assertJsonPath('data.currency', 'UZS')
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonStructure(['data' => ['id', 'from_wallet_id', 'to_wallet_id', 'created_at'], 'meta']);
        self::assertMatchesRegularExpression('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/', $response->json('data.created_at'));
        $this->assertDatabaseHas('billing.wallets', ['id' => $from->id, 'balance' => 700]);
        $this->assertDatabaseHas('billing.wallets', ['id' => $to->id, 'balance' => 300]);
        Event::assertDispatched(TransferCompleted::class);
    }

    public function test_guest_gets401(): void
    {
        $this->postJson(self::URL, [])
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'unauthorized');
    }

    public function test_invalid_input_gets422_with_field_details(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson(self::URL, ['from_wallet_id' => 1, 'to_wallet_id' => 1, 'amount' => -5])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed')
            ->assertJsonStructure(['error' => ['details' => ['to_wallet_id', 'amount']]]);
    }

    public function test_insufficient_balance_gets422_and_changes_nothing(): void
    {
        $user = User::factory()->create();
        $from = $this->wallet($user->id, 100);
        $to = $this->wallet(User::factory()->create()->id, 0);

        $this->actingAs($user, 'sanctum')
            ->postJson(self::URL, ['from_wallet_id' => $from->id, 'to_wallet_id' => $to->id, 'amount' => 300])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'insufficient_balance')
            ->assertJsonPath('error.details.wallet_id', $from->id);

        $this->assertDatabaseHas('billing.wallets', ['id' => $from->id, 'balance' => 100]);
        $this->assertDatabaseCount('billing.transfers', 0);
    }

    public function test_currency_mismatch_gets422(): void
    {
        $user = User::factory()->create();
        $from = $this->wallet($user->id, 1_000);
        $to = $this->wallet(User::factory()->create()->id, 0, 'USD');

        $this->actingAs($user, 'sanctum')
            ->postJson(self::URL, ['from_wallet_id' => $from->id, 'to_wallet_id' => $to->id, 'amount' => 300])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'currency_mismatch');
    }

    public function test_transfer_from_foreign_wallet_gets403(): void
    {
        $user = User::factory()->create();
        $foreign = $this->wallet(User::factory()->create()->id, 1_000);
        $own = $this->wallet($user->id, 0);

        $this->actingAs($user, 'sanctum')
            ->postJson(self::URL, ['from_wallet_id' => $foreign->id, 'to_wallet_id' => $own->id, 'amount' => 300])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'forbidden');
    }

    public function test_missing_wallet_gets404(): void
    {
        $user = User::factory()->create();
        $from = $this->wallet($user->id, 1_000);

        $this->actingAs($user, 'sanctum')
            ->postJson(self::URL, ['from_wallet_id' => $from->id, 'to_wallet_id' => 999_999, 'amount' => 300])
            ->assertNotFound()
            ->assertJsonPath('error.code', 'not_found');
    }

    public function test_view_returns_own_transfer_and_hides_foreign_ones(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $from = $this->wallet($user->id, 1_000);
        $to = $this->wallet($other->id, 0);
        $id = $this->actingAs($user, 'sanctum')
            ->postJson(self::URL, ['from_wallet_id' => $from->id, 'to_wallet_id' => $to->id, 'amount' => 300])
            ->json('data.id');

        $this->actingAs($user, 'sanctum')->getJson(self::URL.'/'.$id)
            ->assertOk()
            ->assertJsonPath('data.id', $id);
        $this->actingAs($other, 'sanctum')->getJson(self::URL.'/'.$id)
            ->assertNotFound()
            ->assertJsonPath('error.code', 'not_found');
    }

    public function test_list_is_paginated_and_filtered(): void
    {
        $user = User::factory()->create();
        $from = $this->wallet($user->id, 1_000);
        $to = $this->wallet(User::factory()->create()->id, 0);
        foreach ([100, 200, 300] as $amount) {
            $this->actingAs($user, 'sanctum')
                ->postJson(self::URL, ['from_wallet_id' => $from->id, 'to_wallet_id' => $to->id, 'amount' => $amount])
                ->assertCreated();
        }

        $this->actingAs($user, 'sanctum')->getJson(self::URL.'?per_page=2&status=completed')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.amount', 300)
            ->assertJsonPath('meta', ['page' => 1, 'per_page' => 2, 'total' => 3, 'total_pages' => 2]);
        $this->actingAs($user, 'sanctum')->getJson(self::URL.'?status=unknown')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed');
    }

    public function test_unknown_route_and_wrong_verb_use_the_error_envelope(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/billing/nothing')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'not_found');
        $this->actingAs($user, 'sanctum')->deleteJson(self::URL)
            ->assertStatus(405)
            ->assertJsonPath('error.code', 'method_not_allowed');
    }

    private function wallet(int $ownerId, int $balance, string $currency = 'UZS'): Wallet
    {
        $wallet = new Wallet;
        $wallet->owner_id = $ownerId;
        $wallet->balance = $balance;
        $wallet->currency = $currency;
        $wallet->save();

        return $wallet;
    }
}
