import { http, HttpResponse } from 'msw';
import { describe, expect, it } from 'vitest';

import { ApiError } from '@/shared/api/ApiError';
import { server } from '@/test/server';

import { errorHandler, transferDto, TRANSFERS_URL } from '../test/handlers';
import { createTransfer, listTransfers } from './transfers.api';

describe('transfers api', () => {
  it('maps the list envelope to a page of camelCase transfers', async () => {
    let query = '';
    server.use(
      http.get(TRANSFERS_URL, ({ request }) => {
        query = new URL(request.url).search;

        return HttpResponse.json({
          data: [transferDto()],
          meta: { page: 2, per_page: 1, total: 3, total_pages: 3 },
        });
      }),
    );

    const page = await listTransfers({ page: 2, perPage: 1, status: 'completed' });

    expect(query).toBe('?status=completed&page=2&per_page=1');
    expect(page).toEqual({
      items: [
        {
          id: 1,
          fromWalletId: 10,
          toWalletId: 20,
          amount: 15050,
          currency: 'USD',
          status: 'completed',
          createdAt: '2026-01-01T12:00:00Z',
        },
      ],
      page: 2,
      perPage: 1,
      total: 3,
      totalPages: 3,
    });
  });

  it('sends snake_case input and returns the created transfer', async () => {
    let body: unknown;
    server.use(
      http.post(TRANSFERS_URL, async ({ request }) => {
        body = await request.json();

        return HttpResponse.json({ data: transferDto({ id: 7 }), meta: {} }, { status: 201 });
      }),
    );

    const transfer = await createTransfer({ fromWalletId: 10, toWalletId: 20, amount: 15050 });

    expect(body).toEqual({ from_wallet_id: 10, to_wallet_id: 20, amount: 15050 });
    expect(transfer.id).toBe(7);
  });

  it('rejects with an ApiError that carries the backend error code and details', async () => {
    server.use(errorHandler('post', 422, 'insufficient_balance', { wallet_id: 10 }));

    const error = await createTransfer({ fromWalletId: 10, toWalletId: 20, amount: 1 }).catch((e: unknown) => e);

    expect(error).toBeInstanceOf(ApiError);
    expect(error).toMatchObject({ status: 422, code: 'insufficient_balance', details: { wallet_id: 10 } });
  });

  it('turns a failed connection into network_error', async () => {
    server.use(http.get(TRANSFERS_URL, () => HttpResponse.error()));

    await expect(listTransfers({ page: 1, perPage: 20 })).rejects.toMatchObject({ code: 'network_error' });
  });
});
