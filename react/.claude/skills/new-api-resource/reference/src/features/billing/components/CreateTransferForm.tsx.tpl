import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';

import { applyServerErrors } from '@/shared/forms/applyServerErrors';

import { transferErrorMessages } from '../errors';
import { useCreateTransfer } from '../hooks/useCreateTransfer';
import type { Transfer } from '../model/transfer';
import {
  createTransferDefaults,
  type CreateTransferFormValues,
  createTransferSchema,
  toCreateTransferInput,
} from '../schemas/createTransfer.schema';

interface Props {
  onCreated?: (transfer: Transfer) => void;
}

export function CreateTransferForm({ onCreated }: Props) {
  const createTransfer = useCreateTransfer();
  const {
    register,
    handleSubmit,
    setError,
    reset,
    formState: { errors },
  } = useForm<CreateTransferFormValues>({
    resolver: zodResolver(createTransferSchema),
    defaultValues: createTransferDefaults,
  });

  const submit = handleSubmit((values) =>
    createTransfer.mutate(toCreateTransferInput(values), {
      onSuccess: (transfer) => {
        reset();
        onCreated?.(transfer);
      },
      onError: (error) =>
        applyServerErrors(error, setError, {
          fields: ['fromWalletId', 'toWalletId', 'amount'],
          messages: transferErrorMessages,
        }),
    }),
  );

  return (
    <form onSubmit={submit} noValidate aria-label="New transfer">
      <div>
        <label htmlFor="fromWalletId">From wallet</label>
        <input id="fromWalletId" inputMode="numeric" aria-invalid={errors.fromWalletId !== undefined} {...register('fromWalletId')} />
        {errors.fromWalletId && <p role="alert">{errors.fromWalletId.message}</p>}
      </div>

      <div>
        <label htmlFor="toWalletId">To wallet</label>
        <input id="toWalletId" inputMode="numeric" aria-invalid={errors.toWalletId !== undefined} {...register('toWalletId')} />
        {errors.toWalletId && <p role="alert">{errors.toWalletId.message}</p>}
      </div>

      <div>
        <label htmlFor="amount">Amount</label>
        <input id="amount" inputMode="decimal" aria-invalid={errors.amount !== undefined} {...register('amount')} />
        {errors.amount && <p role="alert">{errors.amount.message}</p>}
      </div>

      {errors.root?.server && <p role="alert">{errors.root.server.message}</p>}

      <button type="submit" disabled={createTransfer.isPending}>
        {createTransfer.isPending ? 'Sending...' : 'Send'}
      </button>
    </form>
  );
}
