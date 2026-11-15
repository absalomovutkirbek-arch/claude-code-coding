import type { RouteObject } from 'react-router-dom';

/** Routes of the billing feature. Pages are loaded lazily, so each page is its own chunk. */
export const billingRoutes: RouteObject[] = [
  {
    path: '/billing/transfers',
    lazy: async () => ({ Component: (await import('./pages/TransfersPage')).TransfersPage }),
  },
];
