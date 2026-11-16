package com.example.app.modules.billing.repository;

import com.example.app.modules.billing.entity.Transfer;
import com.example.app.modules.billing.enums.TransferStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TransferRepository extends JpaRepository<Transfer, Long> {

    @Query("""
            select t from Transfer t
            where t.initiatorId = :initiatorId
              and (:status is null or t.status = :status)
            order by t.id desc
            """)
    Page<Transfer> pageByInitiator(@Param("initiatorId") long initiatorId, @Param("status") TransferStatus status,
            Pageable pageable);
}
