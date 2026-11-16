import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { describe, expect, it } from 'vitest';

import { renderWithProviders } from '@/test/render';
import { server } from '@/test/server';

import { errorHandler, listTransfersHandler, transferDto, TRANSFERS_URL } from '../test/handlers';
import { TransfersPage } from './TransfersPage';

describe('TransfersPage', () => {
  it('shows the transfers with formatted money', async () => {
    server.use(listTransfersHandler([transferDto({ id: 5 })]));

    renderWithProviders(<TransfersPage />);

    expect(screen.getByText('Loading...')).toBeInTheDocument();
    expect(await screen.findByRole('cell', { name: '5' })).toBeInTheDocument();
    expect(screen.getByRole('cell', { name: /150\.50/ })).toBeInTheDocument();
    expect(screen.getByRole('cell', { name: 'Completed' })).toBeInTheDocument();
  });

  it('shows the empty state', async () => {
    server.use(listTransfersHandler([]));

    renderWithProviders(<TransfersPage />);

    expect(await screen.findByText('No transfers yet.')).toBeInTheDocument();
  });

  it('shows the error state', async () => {
    server.use(errorHandler('get', 403, 'forbidden'));

    renderWithProviders(<TransfersPage />);

    expect(await screen.findByText('Server message for forbidden.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Try again' })).toBeInTheDocument();
  });

  it('requests the page from the URL and moves to the next one', async () => {
    const requested: string[] = [];
    server.use(
      http.get(TRANSFERS_URL, ({ request }) => {
        const page = Number(new URL(request.url).searchParams.get('page'));
        requested.push(String(page));

        return HttpResponse.json({
          data: [transferDto({ id: page * 100 })],
          meta: { page, per_page: 20, total: 60, total_pages: 3 },
        });
      }),
    );

    renderWithProviders(<TransfersPage />, { route: '/billing/transfers?page=2' });

    expect(await screen.findByText('Page 2 of 3')).toBeInTheDocument();
    await userEvent.setup().click(screen.getByRole('button', { name: 'Next' }));
    expect(await screen.findByText('Page 3 of 3')).toBeInTheDocument();
    expect(requested).toEqual(['2', '3']);
  });
});
