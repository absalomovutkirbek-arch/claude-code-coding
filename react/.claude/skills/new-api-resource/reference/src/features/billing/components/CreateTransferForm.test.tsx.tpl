import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { describe, expect, it, vi } from 'vitest';

import { renderWithProviders } from '@/test/render';
import { server } from '@/test/server';

import { errorHandler, transferDto, TRANSFERS_URL } from '../test/handlers';
import { CreateTransferForm } from './CreateTransferForm';

async function fillAndSubmit(from: string, to: string, amount: string) {
  const user = userEvent.setup();
  if (from !== '') await user.type(screen.getByLabelText('From wallet'), from);
  if (to !== '') await user.type(screen.getByLabelText('To wallet'), to);
  if (amount !== '') await user.type(screen.getByLabelText('Amount'), amount);
  await user.click(screen.getByRole('button', { name: 'Send' }));
}

describe('CreateTransferForm', () => {
  it('shows format errors and sends nothing', async () => {
    renderWithProviders(<CreateTransferForm />);

    await fillAndSubmit('1', '1', '');

    expect(await screen.findByText('Source and destination wallets must be different.')).toBeInTheDocument();
    expect(screen.getByText('Enter an amount greater than zero.')).toBeInTheDocument();
  });

  it('submits the amount in minor units and reports the created transfer', async () => {
    let body: unknown;
    server.use(
      http.post(TRANSFERS_URL, async ({ request }) => {
        body = await request.json();

        return HttpResponse.json({ data: transferDto({ id: 7 }), meta: {} }, { status: 201 });
      }),
    );
    const onCreated = vi.fn();
    renderWithProviders(<CreateTransferForm onCreated={onCreated} />);

    await fillAndSubmit('10', '20', '150.5');

    await waitFor(() => expect(onCreated).toHaveBeenCalledWith(expect.objectContaining({ id: 7 })));
    expect(body).toEqual({ from_wallet_id: 10, to_wallet_id: 20, amount: 15050 });
    expect(screen.getByLabelText('Amount')).toHaveValue('');
  });

  it('shows the text for a business error code', async () => {
    server.use(errorHandler('post', 422, 'insufficient_balance', { wallet_id: 10 }));
    renderWithProviders(<CreateTransferForm />);

    await fillAndSubmit('10', '20', '5');

    expect(await screen.findByText('There is not enough money in the source wallet.')).toBeInTheDocument();
  });

  it('puts server validation messages under their fields', async () => {
    server.use(errorHandler('post', 422, 'validation_failed', { to_wallet_id: ['The wallet is closed.'] }));
    renderWithProviders(<CreateTransferForm />);

    await fillAndSubmit('10', '20', '5');

    expect(await screen.findByText('The wallet is closed.')).toBeInTheDocument();
    expect(screen.getByLabelText('To wallet')).toHaveAttribute('aria-invalid', 'true');
  });
});
