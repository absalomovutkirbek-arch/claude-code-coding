import { formatDateTime } from '@/shared/lib/dates';
import { formatMoney } from '@/shared/lib/money';

import { type Transfer, TransferStatus } from '../model/transfer';

const statusLabels: Record<TransferStatus, string> = {
  [TransferStatus.Completed]: 'Completed',
  [TransferStatus.Reversed]: 'Reversed',
};

/** Presentational: receives data through props, knows nothing about queries. */
export function TransferTable({ transfers }: { transfers: Transfer[] }) {
  return (
    <table>
      <thead>
        <tr>
          <th scope="col">ID</th>
          <th scope="col">From</th>
          <th scope="col">To</th>
          <th scope="col">Amount</th>
          <th scope="col">Status</th>
          <th scope="col">Created</th>
        </tr>
      </thead>
      <tbody>
        {transfers.map((transfer) => (
          <tr key={transfer.id}>
            <td>{transfer.id}</td>
            <td>{transfer.fromWalletId}</td>
            <td>{transfer.toWalletId}</td>
            <td>{formatMoney(transfer.amount, transfer.currency)}</td>
            <td>{statusLabels[transfer.status]}</td>
            <td>{formatDateTime(transfer.createdAt)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
