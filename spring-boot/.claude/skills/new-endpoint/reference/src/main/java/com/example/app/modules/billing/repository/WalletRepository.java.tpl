package com.example.app.modules.billing.repository;

import com.example.app.modules.billing.entity.Wallet;
import jakarta.persistence.LockModeType;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface WalletRepository extends JpaRepository<Wallet, Long> {

    /**
     * Loads the wallets with {@code FOR UPDATE}. Ordered by ID so that concurrent transfers lock in the same order.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from Wallet w where w.id in :ids order by w.id")
    List<Wallet> lockByIds(@Param("ids") Collection<Long> ids);
}
