import { QueryClient } from '@tanstack/react-query';

import { isApiError } from './ApiError';

const MAX_RETRIES = 2;

/**
 * Query defaults of the application. Client errors (4xx) are never retried: the answer will not change.
 */
export function createQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        refetchOnWindowFocus: false,
        retry: (failureCount, error) => {
          if (isApiError(error) && error.status >= 400 && error.status < 500) {
            return false;
          }

          return failureCount < MAX_RETRIES;
        },
      },
      mutations: { retry: false },
    },
  });
}
