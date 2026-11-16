package com.example.app.modules.billing.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

/**
 * Table mapping only. Queries live in WalletRepository, rules in TransferService.
 */
@Entity
@Table(name = "wallet", schema = "billing")
public class Wallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "owner_id", nullable = false, updatable = false)
    private long ownerId;

    /** Minor units. */
    @Column(nullable = false)
    private long balance;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(nullable = false, updatable = false, length = 3)
    private String currency;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Wallet() {
        // for JPA
    }

    public static Wallet open(long ownerId, String currency, long balance) {
        Wallet wallet = new Wallet();
        wallet.ownerId = ownerId;
        wallet.currency = currency;
        wallet.balance = balance;

        return wallet;
    }

    public void debit(long amount) {
        balance -= amount;
    }

    public void credit(long amount) {
        balance += amount;
    }

    public Long getId() {
        return id;
    }

    public long getOwnerId() {
        return ownerId;
    }

    public long getBalance() {
        return balance;
    }

    public String getCurrency() {
        return currency;
    }
}
