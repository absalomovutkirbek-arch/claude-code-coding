package com.example.app.modules.billing.controller;

import com.example.app.core.api.ApiResponse;
import com.example.app.core.security.ActorId;
import com.example.app.modules.billing.request.CreateTransferRequest;
import com.example.app.modules.billing.request.ListTransfersRequest;
import com.example.app.modules.billing.response.TransferResponse;
import com.example.app.modules.billing.service.TransferService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/billing/transfers")
public class TransferController {

    private final TransferService service;

    public TransferController(TransferService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TransferResponse> create(@Valid @RequestBody CreateTransferRequest request,
            @ActorId long actorId) {
        return ApiResponse.of(TransferResponse.from(service.create(request.toDto(actorId))));
    }

    @GetMapping("/{id:\\d+}")
    public ApiResponse<TransferResponse> view(@PathVariable long id, @ActorId long actorId) {
        return ApiResponse.of(TransferResponse.from(service.getForActor(id, actorId)));
    }

    @GetMapping
    public ApiResponse<List<TransferResponse>> list(@Valid ListTransfersRequest request, @ActorId long actorId) {
        return ApiResponse.page(service.list(request.toDto(actorId)), TransferResponse::from);
    }
}
