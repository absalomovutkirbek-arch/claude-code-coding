package com.example.app.modules.billing.entity;

import com.example.app.modules.billing.enums.TransferStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "transfer", schema = "billing")
public class Transfer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "initiator_id", nullable = false, updatable = false)
    private long initiatorId;

    @Column(name = "from_wallet_id", nullable = false, updatable = false)
    private long fromWalletId;

    @Column(name = "to_wallet_id", nullable = false, updatable = false)
    private long toWalletId;

    /** Minor units. */
    @Column(nullable = false, updatable = false)
    private long amount;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(nullable = false, updatable = false, length = 3)
    private String currency;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private TransferStatus status;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Transfer() {
        // for JPA
    }

    public static Transfer completed(long initiatorId, Wallet from, Wallet to, long amount) {
        Transfer transfer = new Transfer();
        transfer.initiatorId = initiatorId;
        transfer.fromWalletId = from.getId();
        transfer.toWalletId = to.getId();
        transfer.amount = amount;
        transfer.currency = from.getCurrency();
        transfer.status = TransferStatus.COMPLETED;

        return transfer;
    }

    public Long getId() {
        return id;
    }

    public long getInitiatorId() {
        return initiatorId;
    }

    public long getFromWalletId() {
        return fromWalletId;
    }

    public long getToWalletId() {
        return toWalletId;
    }

    public long getAmount() {
        return amount;
    }

    public String getCurrency() {
        return currency;
    }

    public TransferStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
