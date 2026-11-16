import { createBrowserRouter, Navigate } from 'react-router-dom';

import { billingRoutes } from '@/features/billing';

/** Every route of the application. Features contribute their own route arrays. */
export const router = createBrowserRouter([
  { path: '/', element: <Navigate to="/billing/transfers" replace /> },
  ...billingRoutes,
]);
