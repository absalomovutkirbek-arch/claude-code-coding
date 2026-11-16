package com.example.app.modules.billing.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.app.modules.billing.entity.Wallet;
import com.example.app.modules.billing.event.TransferCompleted;
import com.example.app.modules.billing.repository.WalletRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.event.ApplicationEvents;
import org.springframework.test.context.event.RecordApplicationEvents;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Endpoint test: real routing, validation, security, service, repositories and PostgreSQL.
 */
@SpringBootTest
@AutoConfigureMockMvc
@RecordApplicationEvents
class TransferApiTest {

    private static final String URL = "/api/v1/billing/transfers";
    private static final long USER = 10;
    private static final long OTHER = 20;

    @Autowired
    private MockMvc mvc;

    @Autowired
    private WalletRepository wallets;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private ApplicationEvents events;

    @BeforeEach
    void cleanDatabase() {
        jdbc.execute("TRUNCATE billing.transfer, billing.wallet RESTART IDENTITY CASCADE");
    }

    @Test
    void create_movesMoneyAndReturns201() throws Exception {
        Wallet from = wallet(USER, 1_000, "UZS");
        Wallet to = wallet(OTHER, 0, "UZS");

        transfer(USER, from, to.getId(), 300)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").isNumber())
                .andExpect(jsonPath("$.data.from_wallet_id").value(from.getId()))
                .andExpect(jsonPath("$.data.amount").value(300))
                .andExpect(jsonPath("$.data.currency").value("UZS"))
                .andExpect(jsonPath("$.data.status").value("completed"))
                .andExpect(jsonPath("$.data.created_at").value(matchesPattern("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")))
                .andExpect(jsonPath("$.meta").isMap());

        assertThat(balance(from)).isEqualTo(700);
        assertThat(balance(to)).isEqualTo(300);
        assertThat(events.stream(TransferCompleted.class)).hasSize(1);
    }

    @Test
    void guestGets401() throws Exception {
        mvc.perform(post(URL).contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("unauthorized"));
    }

    @Test
    void invalidInputGets422WithFieldDetails() throws Exception {
        mvc.perform(as(USER, post(URL)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"from_wallet_id\": 1, \"to_wallet_id\": 1, \"amount\": -5}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error.code").value("validation_failed"))
                .andExpect(jsonPath("$.error.details.to_wallet_id").isArray())
                .andExpect(jsonPath("$.error.details.amount").isArray());
    }

    @Test
    void malformedBodyGets400() throws Exception {
        mvc.perform(as(USER, post(URL)).contentType(MediaType.APPLICATION_JSON).content("{not json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("bad_request"));
    }

    @Test
    void insufficientBalanceGets422AndChangesNothing() throws Exception {
        Wallet from = wallet(USER, 100, "UZS");
        Wallet to = wallet(OTHER, 0, "UZS");

        transfer(USER, from, to.getId(), 300)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error.code").value("insufficient_balance"))
                .andExpect(jsonPath("$.error.details.wallet_id").value(from.getId()));

        assertThat(balance(from)).isEqualTo(100);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM billing.transfer", Long.class)).isZero();
        assertThat(events.stream(TransferCompleted.class)).isEmpty();
    }

    @Test
    void currencyMismatchGets422() throws Exception {
        transfer(USER, wallet(USER, 1_000, "UZS"), wallet(OTHER, 0, "USD").getId(), 300)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error.code").value("currency_mismatch"));
    }

    @Test
    void transferFromForeignWalletGets403() throws Exception {
        transfer(USER, wallet(OTHER, 1_000, "UZS"), wallet(USER, 0, "UZS").getId(), 300)
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error.code").value("forbidden"));
    }

    @Test
    void missingWalletGets404() throws Exception {
        transfer(USER, wallet(USER, 1_000, "UZS"), 999_999L, 300)
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("not_found"));
    }

    @Test
    void view_returnsOwnTransferAndHidesForeignOnes() throws Exception {
        transfer(USER, wallet(USER, 1_000, "UZS"), wallet(OTHER, 0, "UZS").getId(), 300);
        long id = jdbc.queryForObject("SELECT id FROM billing.transfer", Long.class);

        mvc.perform(as(USER, get(URL + "/" + id)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(id));
        mvc.perform(as(OTHER, get(URL + "/" + id)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("not_found"));
    }

    @Test
    void list_isPaginatedAndFiltered() throws Exception {
        Wallet from = wallet(USER, 1_000, "UZS");
        Wallet to = wallet(OTHER, 0, "UZS");
        for (long amount : new long[] {100, 200, 300}) {
            transfer(USER, from, to.getId(), amount).andExpect(status().isCreated());
        }

        mvc.perform(as(USER, get(URL).param("per_page", "2").param("status", "completed")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(2)))
                .andExpect(jsonPath("$.data[0].amount").value(300))
                .andExpect(jsonPath("$.meta.page").value(1))
                .andExpect(jsonPath("$.meta.per_page").value(2))
                .andExpect(jsonPath("$.meta.total").value(3))
                .andExpect(jsonPath("$.meta.total_pages").value(2));
        mvc.perform(as(USER, get(URL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(3)));
        mvc.perform(as(USER, get(URL).param("status", "unknown")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error.code").value("validation_failed"))
                .andExpect(jsonPath("$.error.details.status").isArray());
        mvc.perform(as(USER, get(URL).param("per_page", "500")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error.details.per_page").isArray());
    }

    @Test
    void unknownRouteAndWrongVerbUseTheErrorEnvelope() throws Exception {
        mvc.perform(as(USER, get("/api/v1/billing/nothing")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("not_found"));
        mvc.perform(as(USER, get(URL + "/abc")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("not_found"));
        mvc.perform(as(USER, delete(URL)))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.error.code").value("method_not_allowed"));
    }

    private ResultActions transfer(long actorId, Wallet from, Long toWalletId, long amount) throws Exception {
        String body = "{\"from_wallet_id\": %d, \"to_wallet_id\": %d, \"amount\": %d}"
                .formatted(from.getId(), toWalletId, amount);

        return mvc.perform(as(actorId, post(URL)).contentType(MediaType.APPLICATION_JSON).content(body));
    }

    /** The authentication name is the user ID, as ActorIdArgumentResolver expects. */
    private static MockHttpServletRequestBuilder as(long userId, MockHttpServletRequestBuilder request) {
        return request.with(user(String.valueOf(userId)));
    }

    private Wallet wallet(long ownerId, long balance, String currency) {
        return wallets.save(Wallet.open(ownerId, currency, balance));
    }

    private long balance(Wallet wallet) {
        return jdbc.queryForObject("SELECT balance FROM billing.wallet WHERE id = ?", Long.class, wallet.getId());
    }
}
