import type { TransferFilter } from '../model/transfer';

/** Query keys of the transfers resource. The only place where they are written. */
export const transferKeys = {
  all: ['billing', 'transfers'] as const,
  lists: () => [...transferKeys.all, 'list'] as const,
  list: (filter: TransferFilter) => [...transferKeys.lists(), filter] as const,
  detail: (id: number) => [...transferKeys.all, 'detail', id] as const,
};
