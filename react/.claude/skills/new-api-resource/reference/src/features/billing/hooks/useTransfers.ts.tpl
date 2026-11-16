import { keepPreviousData, useQuery } from '@tanstack/react-query';

import { listTransfers } from '../api/transfers.api';
import type { TransferFilter } from '../model/transfer';
import { transferKeys } from './transferKeys';

export function useTransfers(filter: TransferFilter) {
  return useQuery({
    queryKey: transferKeys.list(filter),
    queryFn: () => listTransfers(filter),
    placeholderData: keepPreviousData,
  });
}
