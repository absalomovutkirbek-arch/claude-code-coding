<?php

declare(strict_types=1);

namespace tests\unit\modules\billing;

use app\core\db\TransactionManagerInterface;
use app\core\events\EventDispatcherInterface;
use app\core\exceptions\ForbiddenException;
use app\core\exceptions\NotFoundException;
use app\modules\billing\dto\CreateTransferDto;
use app\modules\billing\events\TransferCompleted;
use app\modules\billing\exceptions\CurrencyMismatchException;
use app\modules\billing\exceptions\InsufficientBalanceException;
use app\modules\billing\models\Transfer;
use app\modules\billing\models\Wallet;
use app\modules\billing\repositories\TransferRepositoryInterface;
use app\modules\billing\repositories\WalletRepositoryInterface;
use app\modules\billing\services\TransferService;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;

final class TransferServiceTest extends TestCase
{
    private WalletRepositoryInterface&MockObject $wallets;
    private TransferRepositoryInterface&MockObject $transfers;
    private EventDispatcherInterface&MockObject $events;
    private TransferService $service;

    protected function setUp(): void
    {
        $this->wallets = $this->createMock(WalletRepositoryInterface::class);
        $this->transfers = $this->createMock(TransferRepositoryInterface::class);
        $this->events = $this->createMock(EventDispatcherInterface::class);

        $transaction = $this->createStub(TransactionManagerInterface::class);
        $transaction->method('run')->willReturnCallback(static fn (callable $callback): mixed => $callback());

        $this->service = new TransferService($this->wallets, $this->transfers, $transaction, $this->events);
    }

    public function test_create_moves_money_and_dispatches_event(): void
    {
        $from = $this->wallet(id: 1, ownerId: 10, balance: 1000);
        $to = $this->wallet(id: 2, ownerId: 20, balance: 50);
        $this->wallets->method('lockByIds')->willReturn([1 => $from, 2 => $to]);
        $this->transfers->expects($this->once())->method('save')->willReturnCallback(
            static function (Transfer $transfer): void {
                $transfer->id = 77;
            },
        );
        $this->events->expects($this->once())->method('dispatch')->with($this->isInstanceOf(TransferCompleted::class));

        $transfer = $this->service->create(new CreateTransferDto(actorId: 10, fromWalletId: 1, toWalletId: 2, amount: 300));

        $this->assertSame(700, $from->balance);
        $this->assertSame(350, $to->balance);
        $this->assertSame(77, $transfer->id);
        $this->assertSame(300, $transfer->amount);
        $this->assertSame('completed', $transfer->status);
    }

    public function test_create_fails_when_balance_is_insufficient(): void
    {
        $this->wallets->method('lockByIds')->willReturn([
            1 => $this->wallet(id: 1, ownerId: 10, balance: 100),
            2 => $this->wallet(id: 2, ownerId: 20, balance: 0),
        ]);
        $this->transfers->expects($this->never())->method('save');
        $this->events->expects($this->never())->method('dispatch');

        $this->expectException(InsufficientBalanceException::class);

        $this->service->create(new CreateTransferDto(actorId: 10, fromWalletId: 1, toWalletId: 2, amount: 101));
    }

    public function test_create_fails_when_actor_does_not_own_source_wallet(): void
    {
        $this->wallets->method('lockByIds')->willReturn([
            1 => $this->wallet(id: 1, ownerId: 10, balance: 100),
            2 => $this->wallet(id: 2, ownerId: 20, balance: 0),
        ]);

        $this->expectException(ForbiddenException::class);

        $this->service->create(new CreateTransferDto(actorId: 20, fromWalletId: 1, toWalletId: 2, amount: 1));
    }

    public function test_create_fails_when_currencies_differ(): void
    {
        $this->wallets->method('lockByIds')->willReturn([
            1 => $this->wallet(id: 1, ownerId: 10, balance: 100, currency: 'UZS'),
            2 => $this->wallet(id: 2, ownerId: 20, balance: 0, currency: 'USD'),
        ]);

        $this->expectException(CurrencyMismatchException::class);

        $this->service->create(new CreateTransferDto(actorId: 10, fromWalletId: 1, toWalletId: 2, amount: 1));
    }

    public function test_create_fails_when_destination_wallet_is_missing(): void
    {
        $this->wallets->method('lockByIds')->willReturn([1 => $this->wallet(id: 1, ownerId: 10, balance: 100)]);

        $this->expectException(NotFoundException::class);

        $this->service->create(new CreateTransferDto(actorId: 10, fromWalletId: 1, toWalletId: 2, amount: 1));
    }

    public function test_get_for_actor_hides_transfers_of_other_users(): void
    {
        $transfer = new Transfer();
        $transfer->setAttributes(['id' => 5, 'initiator_id' => 10], false);
        $this->transfers->method('findById')->willReturn($transfer);

        $this->expectException(NotFoundException::class);

        $this->service->getForActor(5, 99);
    }

    private function wallet(int $id, int $ownerId, int $balance, string $currency = 'UZS'): Wallet
    {
        $wallet = new Wallet();
        $wallet->setAttributes(
            ['id' => $id, 'owner_id' => $ownerId, 'balance' => $balance, 'currency' => $currency],
            false,
        );

        return $wallet;
    }
}
