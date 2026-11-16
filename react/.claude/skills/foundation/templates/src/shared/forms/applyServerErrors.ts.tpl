import type { FieldValues, Path, UseFormSetError } from 'react-hook-form';

import { isApiError } from '@/shared/api/ApiError';

interface Options<T extends FieldValues> {
  /** Form fields that can receive a server message. API names (snake_case) are matched to them in camelCase. */
  fields: readonly Path<T>[];
  /** Text for business error codes of this form, e.g. `{ insufficient_balance: 'Not enough money.' }`. */
  messages?: Record<string, string>;
}

const FALLBACK_MESSAGE = 'Something went wrong. Please try again.';

/**
 * Puts a failed mutation's error into a react-hook-form form:
 * `validation_failed` details go under their fields, everything else under `errors.root.server`.
 */
export function applyServerErrors<T extends FieldValues>(
  error: unknown,
  setError: UseFormSetError<T>,
  { fields, messages = {} }: Options<T>,
): void {
  if (!isApiError(error)) {
    setError('root.server', { type: 'unknown_error', message: FALLBACK_MESSAGE });

    return;
  }

  let applied = false;
  for (const [apiField, fieldMessages] of Object.entries(error.fieldErrors)) {
    const field = fields.find((candidate) => candidate === toCamelCase(apiField));
    if (field !== undefined && fieldMessages.length > 0) {
      setError(field, { type: 'server', message: fieldMessages[0] });
      applied = true;
    }
  }

  if (!applied) {
    setError('root.server', { type: error.code, message: messages[error.code] ?? error.message });
  }
}

function toCamelCase(name: string): string {
  return name.replace(/_([a-z0-9])/g, (_, char: string) => char.toUpperCase());
}
