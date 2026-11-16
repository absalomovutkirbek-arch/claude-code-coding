<?php

declare(strict_types=1);

namespace App\Modules\Billing\Services;

use App\Core\Db\TransactionManagerInterface;
use App\Core\Exceptions\ForbiddenException;
use App\Core\Exceptions\NotFoundException;
use App\Modules\Billing\Dto\CreateTransferDto;
use App\Modules\Billing\Dto\TransferFilterDto;
use App\Modules\Billing\Events\TransferCompleted;
use App\Modules\Billing\Exceptions\CurrencyMismatchException;
use App\Modules\Billing\Exceptions\InsufficientBalanceException;
use App\Modules\Billing\Models\Transfer;
use App\Modules\Billing\Models\Wallet;
use App\Modules\Billing\Repositories\TransferRepositoryInterface;
use App\Modules\Billing\Repositories\WalletRepositoryInterface;
use Illuminate\Contracts\Events\Dispatcher;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

final class TransferService
{
    public function __construct(
        private readonly WalletRepositoryInterface $wallets,
        private readonly TransferRepositoryInterface $transfers,
        private readonly TransactionManagerInterface $transaction,
        private readonly Dispatcher $events,
    ) {}

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
            $from = $wallets->get($dto->fromWalletId) ?? throw new NotFoundException('Source wallet not found.');
            $to = $wallets->get($dto->toWalletId) ?? throw new NotFoundException('Destination wallet not found.');

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
     * @return LengthAwarePaginator<int, Transfer>
     */
    public function list(TransferFilterDto $filter): LengthAwarePaginator
    {
        return $this->transfers->paginate($filter);
    }

    private function assertTransferAllowed(Wallet $from, Wallet $to, CreateTransferDto $dto): void
    {
        if ($from->owner_id !== $dto->actorId) {
            throw new ForbiddenException('You can transfer only from your own wallet.');
        }

        if ($from->currency !== $to->currency) {
            throw new CurrencyMismatchException;
        }

        if ($from->balance < $dto->amount) {
            throw new InsufficientBalanceException($from->id);
        }
    }
}
