import { http, HttpResponse } from 'msw';

/** Wire-format fixtures and handlers of the billing API for tests. */
export const TRANSFERS_URL = '*/api/v1/billing/transfers';

export function transferDto(overrides: Record<string, unknown> = {}) {
  return {
    id: 1,
    from_wallet_id: 10,
    to_wallet_id: 20,
    amount: 15050,
    currency: 'USD',
    status: 'completed',
    created_at: '2026-01-01T12:00:00Z',
    ...overrides,
  };
}

export function listTransfersHandler(items: unknown[], meta: Record<string, number> = {}) {
  return http.get(TRANSFERS_URL, () =>
    HttpResponse.json({
      data: items,
      meta: { page: 1, per_page: 20, total: items.length, total_pages: 1, ...meta },
    }),
  );
}

export function errorHandler(method: 'get' | 'post', status: number, code: string, details?: Record<string, unknown>) {
  return http[method](TRANSFERS_URL, () =>
    HttpResponse.json({ error: { code, message: `Server message for ${code}.`, details } }, { status }),
  );
}
