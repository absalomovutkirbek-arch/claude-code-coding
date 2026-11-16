package com.example.app.modules.billing.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.app.core.exception.ForbiddenException;
import com.example.app.core.exception.NotFoundException;
import com.example.app.modules.billing.dto.CreateTransferDto;
import com.example.app.modules.billing.entity.Transfer;
import com.example.app.modules.billing.entity.Wallet;
import com.example.app.modules.billing.enums.TransferStatus;
import com.example.app.modules.billing.event.TransferCompleted;
import com.example.app.modules.billing.exception.CurrencyMismatchException;
import com.example.app.modules.billing.exception.InsufficientBalanceException;
import com.example.app.modules.billing.repository.TransferRepository;
import com.example.app.modules.billing.repository.WalletRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * Pure unit test: no Spring context, no database. Collaborators are mocked.
 */
@ExtendWith(MockitoExtension.class)
class TransferServiceTest {

    private static final long ACTOR_ID = 10;

    @Mock
    private WalletRepository wallets;

    @Mock
    private TransferRepository transfers;

    @Mock
    private ApplicationEventPublisher events;

    private TransferService service;

    @BeforeEach
    void setUp() {
        service = new TransferService(wallets, transfers, events);
    }

    @Test
    void create_movesMoneyAndPublishesEvent() {
        Wallet from = wallet(1, ACTOR_ID, 1_000, "UZS");
        Wallet to = wallet(2, 20, 500, "UZS");
        when(wallets.lockByIds(List.of(1L, 2L))).thenReturn(List.of(from, to));
        when(transfers.save(any(Transfer.class))).thenAnswer(invocation -> {
            Transfer saved = invocation.getArgument(0);
            ReflectionTestUtils.setField(saved, "id", 77L);
            return saved;
        });

        Transfer transfer = service.create(new CreateTransferDto(ACTOR_ID, 1, 2, 300));

        assertThat(from.getBalance()).isEqualTo(700);
        assertThat(to.getBalance()).isEqualTo(800);
        assertThat(transfer.getAmount()).isEqualTo(300);
        assertThat(transfer.getCurrency()).isEqualTo("UZS");
        assertThat(transfer.getStatus()).isEqualTo(TransferStatus.COMPLETED);
        assertThat(transfer.getInitiatorId()).isEqualTo(ACTOR_ID);
        verify(wallets).save(from);
        verify(wallets).save(to);
        verify(events).publishEvent(new TransferCompleted(77L));
    }

    @Test
    void create_failsWhenBalanceIsInsufficient() {
        Wallet from = wallet(1, ACTOR_ID, 100, "UZS");
        when(wallets.lockByIds(any())).thenReturn(List.of(from, wallet(2, 20, 0, "UZS")));

        assertThatThrownBy(() -> service.create(new CreateTransferDto(ACTOR_ID, 1, 2, 300)))
                .isInstanceOfSatisfying(InsufficientBalanceException.class,
                        exception -> assertThat(exception.errorCode()).isEqualTo("insufficient_balance"));

        assertThat(from.getBalance()).isEqualTo(100);
        verifyNothingIsWritten();
    }

    @Test
    void create_failsWhenCurrenciesDiffer() {
        when(wallets.lockByIds(any()))
                .thenReturn(List.of(wallet(1, ACTOR_ID, 1_000, "UZS"), wallet(2, 20, 0, "USD")));

        assertThatThrownBy(() -> service.create(new CreateTransferDto(ACTOR_ID, 1, 2, 300)))
                .isInstanceOf(CurrencyMismatchException.class);
        verifyNothingIsWritten();
    }

    @Test
    void create_failsWhenActorDoesNotOwnSourceWallet() {
        when(wallets.lockByIds(any()))
                .thenReturn(List.of(wallet(1, 99, 1_000, "UZS"), wallet(2, 20, 0, "UZS")));

        assertThatThrownBy(() -> service.create(new CreateTransferDto(ACTOR_ID, 1, 2, 300)))
                .isInstanceOf(ForbiddenException.class);
        verifyNothingIsWritten();
    }

    @Test
    void create_failsWhenDestinationWalletIsMissing() {
        when(wallets.lockByIds(any())).thenReturn(List.of(wallet(1, ACTOR_ID, 1_000, "UZS")));

        assertThatThrownBy(() -> service.create(new CreateTransferDto(ACTOR_ID, 1, 2, 300)))
                .isInstanceOf(NotFoundException.class);
        verifyNothingIsWritten();
    }

    @Test
    void getForActor_hidesTransfersOfOtherUsers() {
        Transfer foreign = Transfer.completed(99, wallet(1, 99, 0, "UZS"), wallet(2, 20, 0, "UZS"), 300);
        when(transfers.findById(5L)).thenReturn(Optional.of(foreign));

        assertThatThrownBy(() -> service.getForActor(5, ACTOR_ID)).isInstanceOf(NotFoundException.class);
    }

    private void verifyNothingIsWritten() {
        verify(wallets, never()).save(any());
        verify(transfers, never()).save(any());
        verify(events, never()).publishEvent(any());
    }

    private static Wallet wallet(long id, long ownerId, long balance, String currency) {
        Wallet wallet = Wallet.open(ownerId, currency, balance);
        ReflectionTestUtils.setField(wallet, "id", id);

        return wallet;
    }
}
