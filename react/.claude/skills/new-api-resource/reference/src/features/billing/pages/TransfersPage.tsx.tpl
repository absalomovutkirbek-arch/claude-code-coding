import { useSearchParams } from 'react-router-dom';

import { ErrorMessage } from '@/shared/ui/ErrorMessage';
import { Pagination } from '@/shared/ui/Pagination';

import { CreateTransferForm } from '../components/CreateTransferForm';
import { TransferTable } from '../components/TransferTable';
import { useTransfers } from '../hooks/useTransfers';

const PER_PAGE = 20;

/** Route component: reads the URL, calls hooks, composes components. No fetching or business logic here. */
export function TransfersPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const page = Math.max(1, Number(searchParams.get('page')) || 1);
  const transfers = useTransfers({ page, perPage: PER_PAGE });

  return (
    <main>
      <h1>Transfers</h1>
      <CreateTransferForm />

      {transfers.isPending && <p>Loading...</p>}
      {transfers.isError && <ErrorMessage error={transfers.error} onRetry={() => void transfers.refetch()} />}
      {transfers.isSuccess && transfers.data.items.length === 0 && <p>No transfers yet.</p>}
      {transfers.isSuccess && transfers.data.items.length > 0 && (
        <>
          <TransferTable transfers={transfers.data.items} />
          <Pagination
            page={transfers.data.page}
            totalPages={transfers.data.totalPages}
            onChange={(next) => setSearchParams({ page: String(next) })}
          />
        </>
      )}
    </main>
  );
}
