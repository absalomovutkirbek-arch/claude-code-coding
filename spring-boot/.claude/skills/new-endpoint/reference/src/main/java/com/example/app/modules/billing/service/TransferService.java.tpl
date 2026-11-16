package com.example.app.modules.billing.service;

import com.example.app.core.exception.ForbiddenException;
import com.example.app.core.exception.NotFoundException;
import com.example.app.modules.billing.dto.CreateTransferDto;
import com.example.app.modules.billing.dto.TransferFilterDto;
import com.example.app.modules.billing.entity.Transfer;
import com.example.app.modules.billing.entity.Wallet;
import com.example.app.modules.billing.event.TransferCompleted;
import com.example.app.modules.billing.exception.CurrencyMismatchException;
import com.example.app.modules.billing.exception.InsufficientBalanceException;
import com.example.app.modules.billing.repository.TransferRepository;
import com.example.app.modules.billing.repository.WalletRepository;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TransferService {

    private final WalletRepository wallets;
    private final TransferRepository transfers;
    private final ApplicationEventPublisher events;

    public TransferService(WalletRepository wallets, TransferRepository transfers, ApplicationEventPublisher events) {
        this.wallets = wallets;
        this.transfers = transfers;
        this.events = events;
    }

    /**
     * Moves money between two wallets.
     *
     * @throws NotFoundException a wallet does not exist
     * @throws ForbiddenException the actor does not own the source wallet
     * @throws CurrencyMismatchException the wallets have different currencies
     * @throws InsufficientBalanceException the source wallet has too little money
     */
    @Transactional
    public Transfer create(CreateTransferDto dto) {
        Map<Long, Wallet> locked = wallets.lockByIds(List.of(dto.fromWalletId(), dto.toWalletId())).stream()
                .collect(Collectors.toMap(Wallet::getId, Function.identity()));
        Wallet from = require(locked.get(dto.fromWalletId()), "Source wallet not found.");
        Wallet to = require(locked.get(dto.toWalletId()), "Destination wallet not found.");

        assertTransferAllowed(from, to, dto);

        from.debit(dto.amount());
        to.credit(dto.amount());
        wallets.save(from);
        wallets.save(to);

        Transfer transfer = transfers.save(Transfer.completed(dto.actorId(), from, to, dto.amount()));

        // Listeners use @TransactionalEventListener(AFTER_COMMIT): side effects run only after the commit.
        events.publishEvent(new TransferCompleted(transfer.getId()));

        return transfer;
    }

    /**
     * @throws NotFoundException the transfer does not exist or belongs to another user
     */
    @Transactional(readOnly = true)
    public Transfer getForActor(long id, long actorId) {
        return transfers.findById(id)
                .filter(transfer -> transfer.getInitiatorId() == actorId)
                .orElseThrow(() -> new NotFoundException("Transfer not found."));
    }

    @Transactional(readOnly = true)
    public Page<Transfer> list(TransferFilterDto filter) {
        return transfers.pageByInitiator(filter.initiatorId(), filter.status(),
                PageRequest.of(filter.page() - 1, filter.perPage()));
    }

    private void assertTransferAllowed(Wallet from, Wallet to, CreateTransferDto dto) {
        if (from.getOwnerId() != dto.actorId()) {
            throw new ForbiddenException("You can transfer only from your own wallet.");
        }

        if (!from.getCurrency().equals(to.getCurrency())) {
            throw new CurrencyMismatchException();
        }

        if (from.getBalance() < dto.amount()) {
            throw new InsufficientBalanceException(from.getId());
        }
    }

    private static Wallet require(Wallet wallet, String message) {
        if (wallet == null) {
            throw new NotFoundException(message);
        }

        return wallet;
    }
}
