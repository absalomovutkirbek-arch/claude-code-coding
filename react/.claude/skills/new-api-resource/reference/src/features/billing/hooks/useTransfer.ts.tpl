import { useQuery } from '@tanstack/react-query';

import { getTransfer } from '../api/transfers.api';
import { transferKeys } from './transferKeys';

/** `id` usually comes from the URL: an invalid one does not send a request. */
export function useTransfer(id: number) {
  return useQuery({
    queryKey: transferKeys.detail(id),
    queryFn: () => getTransfer(id),
    enabled: Number.isInteger(id) && id > 0,
  });
}
