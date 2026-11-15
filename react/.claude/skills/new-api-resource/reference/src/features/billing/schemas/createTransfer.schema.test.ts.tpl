import { describe, expect, it } from 'vitest';

import { createTransferSchema, toCreateTransferInput } from './createTransfer.schema';

describe('createTransferSchema', () => {
  it('accepts valid values and converts them to API input in minor units', () => {
    const result = createTransferSchema.safeParse({ fromWalletId: '1', toWalletId: '2', amount: '150.5' });

    expect(result.success).toBe(true);
    expect(toCreateTransferInput(result.data!)).toEqual({ fromWalletId: 1, toWalletId: 2, amount: 15050 });
  });

  it('rejects the same wallet on both sides under toWalletId', () => {
    const result = createTransferSchema.safeParse({ fromWalletId: '1', toWalletId: '1', amount: '10' });

    expect(result.success).toBe(false);
    expect(result.error!.issues.map((issue) => issue.path.join('.'))).toEqual(['toWalletId']);
  });

  it.each(['0', '-5', 'abc', ''])('rejects amount %s', (amount) => {
    expect(createTransferSchema.safeParse({ fromWalletId: '1', toWalletId: '2', amount }).success).toBe(false);
  });
});
