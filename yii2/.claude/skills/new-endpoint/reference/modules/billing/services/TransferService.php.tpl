<?php

declare(strict_types=1);

namespace app\modules\billing\services;

use app\core\data\Page;
use app\core\db\TransactionManagerInterface;
use app\core\events\EventDispatcherInterface;
use app\core\exceptions\ForbiddenException;
use app\core\exceptions\NotFoundException;
use app\modules\billing\dto\CreateTransferDto;
use app\modules\billing\dto\TransferFilterDto;
use app\modules\billing\events\TransferCompleted;
use app\modules\billing\exceptions\CurrencyMismatchException;
use app\modules\billing\exceptions\InsufficientBalanceException;
use app\modules\billing\models\Transfer;
use app\modules\billing\models\Wallet;
use app\modules\billing\repositories\TransferRepositoryInterface;
use app\modules\billing\repositories\WalletRepositoryInterface;

final class TransferService
{
    public function __construct(
        private readonly WalletRepositoryInterface $wallets,
        private readonly TransferRepositoryInterface $transfers,
        private readonly TransactionManagerInterface $transaction,
        private readonly EventDispatcherInterface $events,
    ) {
    }

    /**
     * Moves money between two wallets.
     *
     * @throws NotFoundException A wallet does not exist.
     * @throws ForbiddenException The actor does not own the source wallet.
     * @throws CurrencyMismatchException
     * @throws InsufficientBalanceException
     */
    public function create(CreateTransferDto $dto): Transfer
    {
        $transfer = $this->transaction->run(function () use ($dto): Transfer {
            $wallets = $this->wallets->lockByIds([$dto->fromWalletId, $dto->toWalletId]);
            $from = $wallets[$dto->fromWalletId] ?? throw new NotFoundException('Source wallet not found.');
            $to = $wallets[$dto->toWalletId] ?? throw new NotFoundException('Destination wallet not found.');

            $this->assertTransferAllowed($from, $to, $dto);

            $from->balance -= $dto->amount;
            $to->balance += $dto->amount;
            $this->wallets->save($from);
            $this->wallets->save($to);

            $transfer = Transfer::completed($dto->actorId, $from, $to, $dto->amount);
            $this->transfers->save($transfer);

            return $transfer;
        });

        // Side effects run only after the transaction has committed.
        $this->events->dispatch(new TransferCompleted($transfer->id));

        return $transfer;
    }

    /**
     * @throws NotFoundException The transfer does not exist or belongs to another user.
     */
    public function getForActor(int $id, int $actorId): Transfer
    {
        $transfer = $this->transfers->findById($id);

        if ($transfer === null || $transfer->initiator_id !== $actorId) {
            throw new NotFoundException('Transfer not found.');
        }

        return $transfer;
    }

    /**
     * @return Page<Transfer>
     */
    public function list(TransferFilterDto $filter): Page
    {
        return $this->transfers->paginate($filter);
    }

    private function assertTransferAllowed(Wallet $from, Wallet $to, CreateTransferDto $dto): void
    {
        if ($from->owner_id !== $dto->actorId) {
            throw new ForbiddenException('You can transfer only from your own wallet.');
        }

        if ($from->currency !== $to->currency) {
            throw new CurrencyMismatchException();
        }

        if ($from->balance < $dto->amount) {
            throw new InsufficientBalanceException($from->id);
        }
    }
}
