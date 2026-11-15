import { isApiError } from '@/shared/api/ApiError';

interface Props {
  error: unknown;
  /** Text for known error codes. Unknown codes show the message from the API. */
  messages?: Record<string, string>;
  onRetry?: () => void;
}

/** The single way a failed query is shown. */
export function ErrorMessage({ error, messages = {}, onRetry }: Props) {
  const text = isApiError(error)
    ? (messages[error.code] ?? error.message)
    : 'Something went wrong. Please try again.';

  return (
    <div role="alert">
      <p>{text}</p>
      {onRetry !== undefined && (
        <button type="button" onClick={onRetry}>
          Try again
        </button>
      )}
    </div>
  );
}
