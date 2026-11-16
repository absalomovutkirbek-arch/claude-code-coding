<?php

declare(strict_types=1);

namespace Tests\Unit\Modules\Billing;

use App\Core\Db\TransactionManagerInterface;
use App\Core\Exceptions\ForbiddenException;
use App\Core\Exceptions\NotFoundException;
use App\Modules\Billing\Dto\CreateTransferDto;
use App\Modules\Billing\Enums\TransferStatus;
use App\Modules\Billing\Events\TransferCompleted;
use App\Modules\Billing\Exceptions\CurrencyMismatchException;
use App\Modules\Billing\Exceptions\InsufficientBalanceException;
use App\Modules\Billing\Models\Transfer;
use App\Modules\Billing\Models\Wallet;
use App\Modules\Billing\Repositories\TransferRepositoryInterface;
use App\Modules\Billing\Repositories\WalletRepositoryInterface;
use App\Modules\Billing\Services\TransferService;
use Illuminate\Contracts\Events\Dispatcher;
use Illuminate\Support\Collection;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;

/**
 * Pure unit test: no framework boot, no database. Collaborators are mocked by interface.
 */
final class TransferServiceTest extends TestCase
{
    private const ACTOR_ID = 10;

    private WalletRepositoryInterface&MockObject $wallets;

    private TransferRepositoryInterface&MockObject $transfers;

    private Dispatcher&MockObject $events;

    private TransferService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->wallets = $this->createMock(WalletRepositoryInterface::class);
        $this->transfers = $this->createMock(TransferRepositoryInterface::class);
        $this->events = $this->createMock(Dispatcher::class);

        $transaction = new class implements TransactionManagerInterface
        {
            public function run(callable $callback): mixed
            {
                return $callback();
            }
        };

        $this->service = new TransferService($this->wallets, $this->transfers, $transaction, $this->events);
    }

    public function test_create_moves_money_and_dispatches_event(): void
    {
        $from = $this->wallet(1, self::ACTOR_ID, 1_000);
        $to = $this->wallet(2, 20, 500);
        $this->wallets->method('lockByIds')->with([1, 2])->willReturn($this->keyed($from, $to));
        $this->wallets->expects($this->exactly(2))->method('save');
        $this->transfers->expects($this->once())->method('save')
            ->willReturnCallback(static function (Transfer $transfer): void {
                $transfer->id = 77;
            });
        $this->events->expects($this->once())->method('dispatch')
            ->with($this->callback(static fn (TransferCompleted $event): bool => $event->transferId === 77));

        $transfer = $this->service->create(new CreateTransferDto(self::ACTOR_ID, 1, 2, 300));

        self::assertSame(700, $from->balance);
        self::assertSame(800, $to->balance);
        self::assertSame(300, $transfer->amount);
        self::assertSame('UZS', $transfer->currency);
        self::assertSame(TransferStatus::Completed, $transfer->status);
        self::assertSame(self::ACTOR_ID, $transfer->initiator_id);
    }

    public function test_create_fails_when_balance_is_insufficient(): void
    {
        $from = $this->wallet(1, self::ACTOR_ID, 100);
        $this->wallets->method('lockByIds')->willReturn($this->keyed($from, $this->wallet(2, 20, 0)));
        $this->expectNothingIsWritten();

        try {
            $this->service->create(new CreateTransferDto(self::ACTOR_ID, 1, 2, 300));
            self::fail('InsufficientBalanceException was not thrown.');
        } catch (InsufficientBalanceException $exception) {
            self::assertSame('insufficient_balance', $exception->errorCode());
            self::assertSame(100, $from->balance);
        }
    }

    public function test_create_fails_when_currencies_differ(): void
    {
        $this->wallets->method('lockByIds')->willReturn(
            $this->keyed($this->wallet(1, self::ACTOR_ID, 1_000), $this->wallet(2, 20, 0, 'USD')),
        );
        $this->expectNothingIsWritten();

        $this->expectException(CurrencyMismatchException::class);
        $this->service->create(new CreateTransferDto(self::ACTOR_ID, 1, 2, 300));
    }

    public function test_create_fails_when_actor_does_not_own_source_wallet(): void
    {
        $this->wallets->method('lockByIds')->willReturn(
            $this->keyed($this->wallet(1, 99, 1_000), $this->wallet(2, 20, 0)),
        );
        $this->expectNothingIsWritten();

        $this->expectException(ForbiddenException::class);
        $this->service->create(new CreateTransferDto(self::ACTOR_ID, 1, 2, 300));
    }

    public function test_create_fails_when_destination_wallet_is_missing(): void
    {
        $this->wallets->method('lockByIds')->willReturn($this->keyed($this->wallet(1, self::ACTOR_ID, 1_000)));
        $this->expectNothingIsWritten();

        $this->expectException(NotFoundException::class);
        $this->service->create(new CreateTransferDto(self::ACTOR_ID, 1, 2, 300));
    }

    public function test_get_for_actor_hides_transfers_of_other_users(): void
    {
        $transfer = new Transfer;
        $transfer->id = 5;
        $transfer->initiator_id = 99;
        $this->transfers->method('findById')->with(5)->willReturn($transfer);

        $this->expectException(NotFoundException::class);
        $this->service->getForActor(5, self::ACTOR_ID);
    }

    private function expectNothingIsWritten(): void
    {
        $this->wallets->expects($this->never())->method('save');
        $this->transfers->expects($this->never())->method('save');
        $this->events->expects($this->never())->method('dispatch');
    }

    private function wallet(int $id, int $ownerId, int $balance, string $currency = 'UZS'): Wallet
    {
        $wallet = new Wallet;
        $wallet->id = $id;
        $wallet->owner_id = $ownerId;
        $wallet->balance = $balance;
        $wallet->currency = $currency;

        return $wallet;
    }

    /**
     * @return Collection<int, Wallet>
     */
    private function keyed(Wallet ...$wallets): Collection
    {
        return (new Collection($wallets))->keyBy('id');
    }
}
