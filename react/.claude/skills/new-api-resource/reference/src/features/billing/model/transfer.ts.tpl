/** Values of `status` as the API sends them. */
export const TransferStatus = {
  Completed: 'completed',
  Reversed: 'reversed',
} as const;

export type TransferStatus = (typeof TransferStatus)[keyof typeof TransferStatus];

/** A transfer as the application uses it: camelCase, typed status. */
export interface Transfer {
  id: number;
  fromWalletId: number;
  toWalletId: number;
  /** Minor units. */
  amount: number;
  currency: string;
  status: TransferStatus;
  /** ISO 8601, UTC. */
  createdAt: string;
}

export interface TransferFilter {
  status?: TransferStatus;
  page: number;
  perPage: number;
}

export interface CreateTransferInput {
  fromWalletId: number;
  toWalletId: number;
  /** Minor units. */
  amount: number;
}
