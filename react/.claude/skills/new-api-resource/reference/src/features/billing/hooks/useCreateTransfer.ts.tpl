import { useMutation, useQueryClient } from '@tanstack/react-query';

import { createTransfer } from '../api/transfers.api';
import { transferKeys } from './transferKeys';

export function useCreateTransfer() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createTransfer,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: transferKeys.lists() }),
  });
}
