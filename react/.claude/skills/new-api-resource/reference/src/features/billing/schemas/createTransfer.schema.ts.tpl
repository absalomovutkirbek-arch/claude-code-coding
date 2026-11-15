import { z } from 'zod';

import { toMinorUnits } from '@/shared/lib/money';

import type { CreateTransferInput } from '../model/transfer';

const walletId = z
  .string()
  .trim()
  .regex(/^[1-9]\d*$/, 'Enter a wallet number.');

/**
 * Format rules of the transfer form. They mirror the backend's request validation;
 * business rules (balance, ownership, currency) stay on the backend and come back as error codes.
 */
export const createTransferSchema = z
  .object({
    fromWalletId: walletId,
    toWalletId: walletId,
    amount: z
      .string()
      .trim()
      .refine((value) => (toMinorUnits(value) ?? 0) > 0, 'Enter an amount greater than zero.'),
  })
  .refine((values) => values.fromWalletId !== values.toWalletId, {
    path: ['toWalletId'],
    message: 'Source and destination wallets must be different.',
  });

/** What the form fields hold: strings, as the user typed them. */
export type CreateTransferFormValues = z.infer<typeof createTransferSchema>;

export const createTransferDefaults: CreateTransferFormValues = { fromWalletId: '', toWalletId: '', amount: '' };

/** Valid form values -> typed input of the API function. */
export function toCreateTransferInput(values: CreateTransferFormValues): CreateTransferInput {
  return {
    fromWalletId: Number(values.fromWalletId),
    toWalletId: Number(values.toWalletId),
    amount: toMinorUnits(values.amount) ?? 0,
  };
}
