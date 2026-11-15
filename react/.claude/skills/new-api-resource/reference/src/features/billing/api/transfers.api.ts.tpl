import { http } from '@/shared/api/http';
import { type Page, type PageMetaDto, toPage } from '@/shared/api/types';

import type { CreateTransferInput, Transfer, TransferFilter, TransferStatus } from '../model/transfer';

/** A transfer exactly as the API sends it. Never leaves this file. */
interface TransferDto {
  id: number;
  from_wallet_id: number;
  to_wallet_id: number;
  amount: number;
  currency: string;
  status: TransferStatus;
  created_at: string;
}

const URL = '/billing/transfers';

function toTransfer(dto: TransferDto): Transfer {
  return {
    id: dto.id,
    fromWalletId: dto.from_wallet_id,
    toWalletId: dto.to_wallet_id,
    amount: dto.amount,
    currency: dto.currency,
    status: dto.status,
    createdAt: dto.created_at,
  };
}

export async function listTransfers(filter: TransferFilter): Promise<Page<Transfer>> {
  const response = await http.get<TransferDto[], PageMetaDto>(URL, {
    status: filter.status,
    page: filter.page,
    per_page: filter.perPage,
  });

  return toPage(response, toTransfer);
}

export async function getTransfer(id: number): Promise<Transfer> {
  const response = await http.get<TransferDto>(`${URL}/${id}`);

  return toTransfer(response.data);
}

export async function createTransfer(input: CreateTransferInput): Promise<Transfer> {
  const response = await http.post<TransferDto>(URL, {
    from_wallet_id: input.fromWalletId,
    to_wallet_id: input.toWalletId,
    amount: input.amount,
  });

  return toTransfer(response.data);
}
